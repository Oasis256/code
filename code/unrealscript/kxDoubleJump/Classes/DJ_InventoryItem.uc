//================================================================================
// DJ_InventoryItem.
//================================================================================

// TODO: If we have normal jump boots, our in-air doublejumps also jump with their strength.  I think this is wrong - we should ideally prevent the jump boots from being used in-air, but keep their charge.

class DJ_InventoryItem extends TournamentPickup config(kxDoubleJump);

var() config int MaxJumps;
var() config float JumpHeight;
var() config float VelocityLimit;
var() config int JumpType;
var() config int JumpStyle;
var() config float RechargeRate;
var() config bool bRestrictFC;
var int nofJumps;
var int nofJumpKeys;
var float LastJumpTime;

replication
{
  reliable if ( Role == 4 )
    ClientPlayAnim;
  reliable if ( Role < 4 )
    DoubleJump;
}

simulated function PreBeginPlay ()
{
  local PlayerPawn P;

  if ( Level.NetMode == 1 )
  {
    return;
  }
  foreach AllActors(Class'PlayerPawn',P)
  {
    if ( Viewport(P.Player) != None ) {
      break;
    } else {
      P = None;
    }
  }
  if ( P == None )
  {
    Log("DJ: NO LOCAL PLAYERPAWN !!!");
    return;
  }
  InitializeKeys(P);
  if ( nofJumpKeys == 0 ) {
    Log("DJ: Could NOT find any keys bound to JUMP/DOUBLEJUMP, DoubleJump will NOT work !!!");
  } else {
  }
}

simulated function InitializeKeys (PlayerPawn P)
{
  local string KeyName;
  local string keyBinding;
  local int i;

  nofJumpKeys = 0;
  for (i=0;i<256;i++) {
    KeyName = P.ConsoleCommand("Keyname" @ string(i));
    if ( (InStr(P.ConsoleCommand("Keybinding" @ KeyName),"Jump") != -1) && (InStr(P.ConsoleCommand("Keybinding" @ KeyName),"DoubleJump") == -1) )
    {
      keyBinding = P.ConsoleCommand("Keybinding" @ KeyName);
      P.ConsoleCommand("SET INPUT" @ KeyName @ "DoubleJump|" $ keyBinding);
      Log("DJ: Changed" @ KeyName @ "from" @ keyBinding @ "to DoubleJump|" $ keyBinding);
      nofJumpKeys++;
    } else {
      if ( InStr(P.ConsoleCommand("Keybinding" @ KeyName),"DoubleJump") != -1 )
      {
        nofJumpKeys++;
      }
    }
  }
}

exec function DoubleJump ()
{
  local PlayerPawn P;

  if ( PlayerPawn(Owner) == None )
  {
    return;
  }
  P = PlayerPawn(Owner);
  if (RechargeRate>0 && (Level.TimeSeconds-LastJumpTime)>=RechargeRate && nofJumps>1) {
    nofJumps = 1;
  }
  if (bRestrictFC && P.PlayerReplicationInfo.HasFlag != None && nofJumps<MaxJumps) {
    nofJumps = MaxJumps-1;
  }
  if ( P.Physics == 2 )
  {
    if ( nofJumps < MaxJumps )
    {
      switch (JumpType)
      {
        case 0:
          if (Abs(P.Velocity.Z) > VelocityLimit) { // Not at apex
            return;
          }
        break;
        case 1:
          if (P.Velocity.Z < -VelocityLimit) { // Falling fast
            return;
          }
        break;
        default:
      }

      switch (JumpStyle) {
        case 0:
          P.Velocity.Z = P.JumpZ * JumpHeight;
        break;
        case 1:
          //// If we are already goin up fast, give us only half a jump extra
          P.Velocity.Z = P.Velocity.Z + 0.5 * P.JumpZ * JumpHeight;
          //// If we are not going up at jump speed, make us go up at jump speed!
          if (P.Velocity.Z < P.JumpZ * JumpHeight) {
            P.Velocity.Z = P.JumpZ * JumpHeight;
          }
        break;
        case 2:
          //// Add extra jump to current upward velocity.  This can take you very high if tapped quickly, so in this case JumpType=on-apex is recommended.
          P.Velocity.Z += P.JumpZ * JumpHeight;
        break;
        case 3:
          //// Let the player choose whether to go for height or distance on the secondary jumps:
          //// Add extra jump to current velocity (half up, half "with" our sideways velocity)
          // P.Velocity.Z += P.JumpZ * JumpHeight * 0.5;
          // P.Velocity = Normal(P.Velocity) * (VSize(P.Velocity) + P.JumpZ * JumpHeight * 0.5);
        break;
        default:
          P.Velocity.Z = P.JumpZ * JumpHeight;
        break;
      }

      nofJumps++;
      LastJumpTime = Level.TimeSeconds;

      P.PlaySound(P.JumpSound,SLOT_Interface,1.5,True,1200.0,1.0);
      if ( (Level.Game != None) && (Level.Game.Difficulty > 0) ) {
        P.MakeNoise(0.1 * Level.Game.Difficulty);
      }
      if ( nofJumps == MaxJumps ) {
        SetFinalMesh(P);
      }
    }
  } else {
    P.DoJump();
    nofJumps = 1;
    LastJumpTime = Level.TimeSeconds;
  }
}

simulated function SetFinalMesh(PlayerPawn P) {
  local name newMesh;
  local float forwardness,rightness;
  local Rotator right;
  newMesh = '';
  forwardness = Normal(P.Velocity) Dot Normal(Vector(P.Rotation));
  right = P.Rotation;
  right.Yaw += 16384;
  rightness = Normal(P.Velocity) Dot Normal(Vector(right));
  // if ( sqrt(forwardness*forwardness+rightness*rightness)<0.2 && P.HasAnim('Flip')) {
    // newMesh = 'Flip';
  if ( sqrt(P.Velocity.X*P.Velocity.X+P.Velocity.Y*P.Velocity.Y)<120) { // && P.HasAnim('Flip')) {
    //// Do not change mesh.
    // newMesh = 'Flip';
  } else if ( rightness > Abs(forwardness) && P.HasAnim('ROLLRIGHT') ) {
    newMesh = 'ROLLRIGHT';
  } else if ( rightness > Abs(forwardness) && P.HasAnim('DodgeL') ) {
    newMesh = 'DodgeL';
  } else if ( rightness < (-Abs(forwardness)) && P.HasAnim('ROLLLEFT') ) {
    newMesh = 'ROLLLEFT';
  } else if ( rightness < (-Abs(forwardness)) && P.HasAnim('DodgeR') ) {
    newMesh = 'DodgeR';
  } else if ( forwardness < (-Abs(rightness)) && P.HasAnim('DodgeB') ) {
    newMesh = 'DodgeB';
  } else if ( P.HasAnim('Flip') ) { /*forwardness>Abs(rightness) &&*/
    newMesh = 'Flip';
  }
  if (newMesh != '' && P.HasAnim(newMesh)) {
    P.PlayAnim(newMesh,1.352 * FMax(0.34999999,Region.Zone.ZoneGravity.Z / Region.Zone.Default.ZoneGravity.Z),0.06);
    if ( Level.NetMode != 0 ) {
      ClientPlayAnim(newMesh,1.352 * FMax(0.34999999,Region.Zone.ZoneGravity.Z / Region.Zone.Default.ZoneGravity.Z),0.06);
    }
  }
}

simulated function ClientPlayAnim (name Sequence, optional float Rate, optional float TweenTime) {
  Owner.PlayAnim(Sequence,Rate,TweenTime);
}

defaultproperties {
    nofJumps=1
    ExpireMessage="ExpireMessage"
    PickupMessage="PickupMessage"
    ItemName="DoubleJumpUT"
    // TODO: ItemName="DoubleJumpItem"
    Mesh=LodMesh'Botpack.jboot'
    AmbientGlow=0

    MaxJumps=3

    // DJ:
    JumpHeight=1.20
    VelocityLimit=100
    JumpType=1
    JumpStyle=0

    // kx:
    // JumpHeight=1.20
    // VelocityLimit=120
    // JumpType=0
    // JumpStyle=2

    // VelocityLimit=80 // slightly harder because we use additional velocity - actually 100 seems hard enough ;p

    RechargeRate=5.0
    bRestrictFC=True
}
