// TODO: We didn't really need to give the player those weapons, since LMS will probably suit them up anyway.
//       But maybe we aren't in the LMS gametype.  In which case, we should probably remove weapons and other pickup items from the map.
// TODO BUG: Were some of the armor+pads getting left invisible on the spawnpoints?  I kept spawning with 150, but maybe that was done by normal LMS.
// TODO: Anti-camper detection.
// TODO: I didn't hear the amp pickup sound (altho maybe it came the same time as "headshot")
// DONE: Sucks to get Armour then Armour again, etc.  :P
// TODO: Deemer
// DONE: I spawned with shieldbelt.
// My Invis refused to wear off.
// Redeemer fire works but not altfire.
// DONE: WarheadLauncher DM-Liandri.WarheadLauncher0 (Function Botpack.WarheadLauncher.AltFire:002C) Accessed None
// DONE: WarheadLauncher DM-Liandri.WarheadLauncher12 (Function Botpack.WarheadLauncher.RateSelf:0027) Accessed None
// LMS seems a bit stingy on initial ammo.
// TODO: It is sometimes a bit laggy to load a new external object (e.g. the siege jetpack) during play due to DynamicLoadObject() calls.
//       Since one is likely to spawn during the game anyway, have server and client pre-load the Powerups resources before the game starts.
// TODO: I think you only get given one WarheadLauncher per life.  This is a feature, so ensure it stays that way!
// TODO: Detect last 2 players, display it, and then stop giving powerups+health.
// DONE: Some errors from the bots - are they due to pathing on spawned items which they think are navigable to/through?  Seemed to be fixed with some more additions to GiveInventory().
// TODO: Rather than watch health go down 2 points each second, set the timer frequency calculated to remove 1hp each call to Timer().
// TODO: zeroping weapons not working, piglet wants "+50" txt, or happy with healthsound instead.
//       initial armour and health got set by LMS.
// DONE: (i think) Player is Out.
// TODO: invis lasts too long
// TODO: Ammo is not working!
// In LMS fragged players are not dropping their weapons?!  Then we really must increase their ammo!
// TODO: Still showing "Large Bullets"

class FairLMS expands Mutator config(FairLMS);

struct LMSBonus {
	var String Type;
	var Color Color;
	var String Name;  // If not set, defaults to item's ItemName.
	var String Sound; // If not set, defaults to item's PickupSound.
};

var config bool bLogging;
var config bool bGiveWeapons;
var config int InitialArmour,InitialHealth;
var config float HealthLostPerSec,HealthGainedPerKill;
var config bool bGivePowerups;
var config int FragsForPowerup;
var config Color MessageColor;
var config Sound PowerupSound;
var config String InitialWeapon[20];
var config LMSBonus Powerup[20];

var int KillsSinceSpawn[64];
var bool bGameStarted,bTwoPlayersLeft;

var float TimerLast;
var float TimerAverage;
var int TimerCount;

function PostBeginPlay() {
	local Mutator m;
	foreach AllActors(class'Mutator',m) {
		if (m.class == Self.class && m!=Self) {
			Log(Self$".PostBeginPlay() Found another copy "$m$" so self-destructing.");
			Self.Destroy();
			return;
		}
	}
	Super.PostBeginPlay();
	SetTimer(1.0/HealthLostPerSec,True);
	if (HealthLostPerSec>0 || HealthGainedPerKill>0)
		Level.Game.GameName = "Anti-Camping "$ Level.Game.GameName;
	if (bGivePowerups)
		Level.Game.GameName = Level.Game.GameName $" with Bonus Powerups";
	if (HealthLostPerSec>0)
		DeathMatchPlus(Level.Game).StartMessage = "Your are losing health!  Kill to stay alive!";

	// TESTING: Turn redeemers into mini-redeemers.  I think this is working!
	// TODO CHECK: Do these changes propogate over maps, messing with other types of game, or next round of LMS?
	// CONSIDER: If setting defaults doesn't work, change values after it has spawned.  (CheckReplacement() / IsRelevant()?)
	Log(Self.class$" Changing Warhead speed from "$ class'WarShell'.default.DrawScale );
	class'WarheadLauncher'.default.ItemName = "Mini Redeemer";
	class'WarShell'.default.DrawScale = class'WarShell'.default.DrawScale * 0.3;
	Log(Self.class$"                          to "$ class'WarShell'.default.DrawScale );
	class'WarShell'.default.Speed = class'WarShell'.default.Speed * 0.3;
	class'WarShell'.default.Damage = class'WarShell'.default.Damage * 0.3;
	class'WarShell'.default.MomentumTransfer = class'WarShell'.default.MomentumTransfer * 0.3;
	class'GuidedWarShell'.default.DrawScale = class'GuidedWarShell'.default.DrawScale * 0.3;
	class'GuidedWarShell'.default.Speed = class'GuidedWarShell'.default.Speed * 0.3;
	class'GuidedWarShell'.default.Damage = class'GuidedWarShell'.default.Damage * 0.3;
	class'GuidedWarShell'.default.MomentumTransfer = class'GuidedWarShell'.default.MomentumTransfer * 0.3;
	//// TODO: Value sometimes set from PostBeginPlay().  We should intercept just after creation.  bIsRelevant/CheckReplacement?
	class'WarExplosion'.default.DrawScale = class'WarExplosion'.default.DrawScale * 0.3;
	class'WarExplosion2'.default.DrawScale = class'WarExplosion2'.default.DrawScale * 0.3;
}

event Timer() {
	local Pawn p;
	local PlayerPawn pp;
	local int aliveCount;
	local String players;
	local Inventory inv;
	if (bLogging) {
		TimerAverage = ( TimerAverage*TimerCount + (Level.TimeSeconds-TimerLast)*1 ) / (TimerCount+1);
		TimerCount++;
		// Log("FairLMS.Timer() at "$Level.TimeSeconds$" gap "$ (Level.TimeSeconds-TimerLast) );
		Log("FairLMS.Timer() at "$Level.TimeSeconds$" gap "$ (Level.TimeSeconds-TimerLast) $" average "$TimerAverage);
		TimerLast = Level.TimeSeconds;
	}
	Super.Timer();
	foreach AllActors(class'Pawn',p) {
		if ((PlayerPawn(p)!=None || Bot(p)!=None) && Spectator(p)==None) {
			if (!bGameStarted) {
				for (Inv=p.Inventory; Inv!=None; Inv=Inv.Inventory) {
					if (Inv.IsA('Weapon')) {
						bGameStarted = True;
						break;
					}
				}
			}
			if (!bTwoPlayersLeft) {
				p.Health -= 1;
				if (p.Health == 0)
					// FlashMessage(p,"You are about to die!  Kill to survive!",MessageColor);
					FlashMessage(p,"You have low health ... Kill someone quickly!",MessageColor);
					p.bUnlit=True;
				if (p.Health <= -15) {
					p.Died(None, 'Suicided', p.Location);
					// TODO: make a puff of smoke appear here!!! xD
				}
			}
		}
		if (p.PlayerReplicationInfo!=None && p.PlayerReplicationInfo.Score>0) {
			aliveCount++;
			if (aliveCount<3) {
				if (players == "")
					players = p.getHumanName() $ " v";
				else
					players = players $ " " $ p.getHumanName();
			}
		}
	}
	if (bGameStarted && LastManStanding(Level.Game)!=None && aliveCount==2 && !bTwoPlayersLeft && FRand()<0.2) { // Delay to avoid get overwritten by LastManStanding.
		foreach AllActors(class'PlayerPawn',pp) {
			FlashMessage(pp,"Two players left:",MessageColor,3,true);
			FlashMessage(pp,players,MessageColor,4,true);
			BroadcastMessage("Two players left: "$players);
			// TODO: switch everyone's music >.<
		}
		bTwoPlayersLeft = True;
	}
}

function ModifyPlayer(Pawn p) {
	p.bUnlit=False;
	Super.ModifyPlayer(p);
	if (InitialHealth>0)
		p.Health = InitialHealth;
	// p.PlayerReplicationInfo.Armor = InitialArmour;
	GiveAllWeapons(p);
	if (p.PlayerReplicationInfo!=None) {
		KillsSinceSpawn[p.PlayerReplicationInfo.PlayerID%64] = 0;
	}
}

function ScoreKill(Pawn killer, Pawn other) {
	Super.ScoreKill(killer,other);
	if (killer != None) {
		if (!bTwoPlayersLeft) {
			killer.Health += HealthGainedPerKill;
			if (killer.Health > 199) killer.Health = 199;
			killer.PlaySound(class'Botpack.TournamentHealth'.default.PickupSound,SLOT_Interface,3.0);
			if (killer.PlayerReplicationInfo!=None) {
				KillsSinceSpawn[killer.PlayerReplicationInfo.PlayerID%64] += 1;
				if (bGivePowerups && KillsSinceSpawn[killer.PlayerReplicationInfo.PlayerID%64]%FragsForPowerup == 0) {
					GiveRandomPowerup(killer);
				}
			}
		}
	}
}

function GiveArmor(Pawn p) {
}

function GiveAllWeapons(Pawn p) {
	local Inventory Inv;
	local int i;
	local class<Weapon> type;

	// Give appropriate armour.
	// CONSIDER: Alternatively, give them normal armour, but adjust its Charge.
	if (InitialArmour<50) {
	} else if (InitialArmour>=50 && InitialArmour<100) {
		GivePickupType(p,class'ThighPads');
	} else if (InitialArmour>=100 && InitialArmour<150) {
		GivePickupType(p,class'Armor2');
	} else if (InitialArmour>=150) {
		GivePickupType(p,class'Armor2');
		GivePickupType(p,class'ThighPads');
	}

	if (bGiveWeapons) {
		for (i=0;i<20;i++) {
			if (InitialWeapon[i]!="") {
				type = class<Weapon>(DynamicLoadObject(InitialWeapon[i],class'class'));
				Inv = p.FindInventoryType(type);
				if (Inv == None) {
					DeathMatchPlus(Level.Game).GiveWeapon(p,InitialWeapon[i]);
				} else {
					// WarnMsg(Self$".GiveAllWeapons() Warning! "$p.getHumanName()$" already had a "$type$" so re-using it "$Inv);
					Log(Self$".GiveAllWeapons() Warning! "$p.getHumanName()$" already had a "$type$" so re-using it "$Inv);
					// Maybe this is not needed.  My actual problem was adding a SniperRifle to a player that already had a zp_SniperRifle.
				}
			}
		}
	}

}

function WarnMsg(String Msg) {
	BroadcastMessage("[WARN] "$Msg);
}

function Inventory GivePickupType(Pawn p, class<Inventory> t) {
	// TODO: Can we just grab the implementation in GiveRandomPowerup()?
	local Inventory Inv;
	Inv = p.FindInventoryType(t);
	if (Inv!=None) {
		// Log(Self$".GivePickupType() Warning! "$p.getHumanName()$" already had a "$t$" so re-using it "$Inv);
		Log(Self$".GivePickupType() "$p.getHumanName()$" already has a "$Inv$" - destroying it.");
		Inv.Destroy();
		Inv = None;
		// TODO: This might be a bummer if it destroys the weapon you are currently holding!
	}
	// In the case of amp at least, re-using is bad because you don't get the fresh charge!
	if (Inv==None) {
		// Log(Self$".GivePickupType() Spawning a new "$t$" for "$p.getHumanName());
		Inv = Spawn(t,p);
	}
	if (Inv==None) {
		Log(Self$".GivePickupType() Warning! Failed to spawn a "$t);
	} else {
		GiveInventory(p,Inv);

		// Post-hacks:
		if (Weapon(Inv)!=None) {
			// Really for the redeemer.  CHECK: may not be needed
			if (Weapon(Inv).AmmoType.AmmoAmount<1)
				Weapon(Inv).AmmoType.AmmoAmount = 1;
		}
	}
	return Inv;
}

function GiveInventory(Pawn p, Inventory inv) {
	local Weapon w;

	inv.bHeldItem=True;
	inv.RespawnTime=0;

	w = Weapon(inv);
	if (w!=None) {

		// Handle Weapon:
		w.Instigator = P;
		w.BecomeItem();
		P.AddInventory(w);
		// w.GiveTo(p);
		w.GiveAmmo(P);
		// Not for the redeemer (or other 1 ammo weapons):
		if (Weapon(inv)!=None && Weapon(inv).AmmoType!=None && Weapon(inv).AmmoType.AmmoAmount>1) {
			// Increase ammo x 3
			Weapon(inv).AmmoType.AmmoAmount = Weapon(inv).AmmoType.AmmoAmount * 3;
		}
		w.SetSwitchPriority(P);
		w.WeaponSet(P);
		w.AmbientGlow = 0;

		// DeathMatchPlus does this to weapons:
		if ( p.IsA('PlayerPawn') )
			w.SetHand(PlayerPawn(p).Handedness);
		else
			w.GotoState('Idle');

	} else {

		// Handle other Inventory item:
		inv.GiveTo(p);
		inv.Activate();

	}
	// DONE: Check out what DeathMatchPlus, and Translocator/GrappleGun do to initialise weapons correctly.
	//       We may be missing something we should do for weapons.  In a game with bots I got: WarheadLauncher DM-Liandri.WarheadLauncher3 (F_nction Botpack.WarheadLauncher.RateSelf:0027) Accessed None
}

function GiveRandomPowerup(Pawn p) {
	local int i,j;
	local class<Inventory> type;
	local Inventory inv;
	local Color col;
	local Sound resource;
	for (j=0;j<100;j++) {
		i = 20*FRand();
		if (Powerup[i].Type == "")
			continue;
		type = class<Inventory>( DynamicLoadObject(Powerup[i].Type,class'Class') );
		if (type == None) {
			Log("[FairLMS] Powerup #"$i$" \""$Powerup[i].Type$"\" does not exist!");
			continue;
		}
		inv = p.FindInventoryType(type);
		if (inv != None) {
			// A bit log spammy:
			// Log(Self$".GiveRandomPowerup() "$p.getHumanName()$" already has a "$inv);
			// Log(Self$".GiveRandomPowerup() maybe they don't want another - maybe we could upgrade it?");
			// It seems to me that items *are* being removed from a player's inventory when he loses them.
			// I don't know if warhead 2nd time around is working now.
			continue;
		}
		inv = Spawn(type,p);
		if (inv == None) {
			Log(Self$".GiveRandomPowerup() Failed to spawn "$type);
			continue;
		}

		// OK we have created the powerup, we can give it to the player:
		GiveInventory(p,inv);

		col = Powerup[i].Color;
		if (col.R==0 && col.G==0 && col.B==0) {
			col.R=255; col.G=255; col.B=16; col.A=16;
		}
		if (Powerup[i].Name == "")
			Powerup[i].Name = inv.ItemName;
		FlashMessage(p,"-+- "$Caps(Powerup[i].Name)$" -+-",col);

		// DONE: Sound!
		resource = None;
		if (Powerup[i].Sound != "") {
			resource = Sound(DynamicLoadObject(Powerup[i].Sound,class'Sound'));
		}
		if (resource != None) {
			p.PlaySound(resource,SLOT_Interface,5.0);
		} else {
			if (Inv.PickupSound != None) {
				p.PlaySound(Inv.PickupSound,SLOT_Interface,5.0);
			} else {
				p.PlaySound(PowerupSound,SLOT_Interface,5.0);
			}
		}

		return;

	}
	if (j==100) {
		Log(Self$".GiveRandomPowerup() Tried 100 times but could not find a suitable powerup!  Maybe "$p.getHumanName()$" has everything already.");
		// TODO: maybe remove something from his inventory and retry?  Then at least he could get a fresh one.
		BroadcastMessage(p.getHumanName()$" is MAXXED OUT!");
	}

}

function FlashMessage(Pawn p, String msg, Color col, optional int line, optional bool bMoreComing) {
	if (PlayerPawn(p)==None)
		return;
	if (line == 0) line=4;
	// msg = Caps(msg) $ "!";
	if (!bMoreComing)
		PlayerPawn(p).ClearProgressMessages();
	PlayerPawn(p).SetProgressTime(3.0);
	PlayerPawn(p).SetProgressColor(col,line);
	PlayerPawn(p).SetProgressMessage(msg,line);
}

function Mutate(String msg, PlayerPawn Sender) {
	local String rep;
	local Inventory inv;
	local Sound snd;

	if (msg ~= "LISTINV") {

		rep = "";
		for (Inv=Sender.Inventory; Inv!=None; Inv=Inv.Inventory) {
			// rep = rep $ Inv $"("$ Inv.getHumanName() $") ";
			rep = rep $ Inv $" ";
			if (Len(rep)>1500) {
				rep = rep $ "...";
				break;
			}
		}
		Sender.ClientMessage("Your inventory: "$rep);

	} else if (Left(msg,10) ~= "TESTSOUND ") {

		snd = Sound(DynamicLoadObject(Mid(msg,10),class'Sound'));
		if (snd == None) {
			Sender.ClientMessage("Failed to load sound \""$ Mid(msg,10) $"\".");
		} else {
			Sender.PlaySound(snd,SLOT_Interface,3.0);
		}

	}
	Super.Mutate(msg,Sender);
}

defaultproperties {
	bLogging=True
	bGiveWeapons=False  // Handled by LMS
	InitialArmour=123   // Handled by LMS
	InitialHealth=123   // Handled by LMS?
	// InitialArmour=100
	HealthLostPerSec=2.0
	HealthGainedPerKill=50.0
	bGivePowerups=True
	FragsForPowerup=3
	MessageColor=(R=255,G=255,B=31,A=0)
	PowerupSound=Sound'Botpack.Pickups.BeltSnd'
	InitialWeapon(0)="Botpack.ImpactHammer"
	InitialWeapon(1)="Botpack.Enforcer"
	InitialWeapon(2)="Botpack.UT_BioRifle"
	InitialWeapon(3)="Botpack.PulseGun"
	InitialWeapon(4)="Botpack.Minigun2"
	InitialWeapon(5)="Botpack.UT_FlakCannon"
	InitialWeapon(6)="Botpack.UT_EightBall"
	InitialWeapon(7)="Botpack.ShockRifle"
	InitialWeapon(8)="Botpack.SniperRifle"
	// PowerupSound=Sound'Botpack.Pickups.Sbelthe2'
	// PowerupSound=Sound'Botpack.Pickups.AmpOut'
	Powerup(0)=(Type="Botpack.HealthPack",Color=(R=131,G=255,B=131,A=32))
	Powerup(1)=(Type="Botpack.Armor2",Color=(R=255,G=131,B=91,A=32))
	Powerup(2)=(Type="Botpack.UDamage",Color=(R=192,G=31,B=192,A=32))
	Powerup(3)=(Type="Botpack.UT_Stealth",Color=(R=3,G=3,B=150,A=48))
	Powerup(4)=(Type="Botpack.UT_ShieldBelt",Color=(R=255,G=255,B=31,A=32))
	Powerup(5)=(Type="Botpack.UT_JumpBoots",Color=(R=91,G=255,B=255,A=32))
	Powerup(6)=(Type="Botpack.WarheadLauncher",Color=(R=180,G=21,B=21,A=32))
	Powerup(7)=(Type="SiegeXXL2e.JetPack",Color=(R=91,G=192,B=255,A=32))
	Powerup(8)=(Type="kxGrapple.GrappleGun",Color=(R=91,G=50,B=12,A=32))
	Powerup(9)=(Type="kxDoubleJump.DoubleJumpBoots",Color=(R=91,G=255,B=255,A=32))
	// Disabled some since something was giving me "Large Bullets" :P
	// Powerup(11)=(Type="Botpack.EClip",Color=(R=102,G=102,B=102,A=32))
	Powerup(12)=(Type="Botpack.BioAmmo",Color=(R=102,G=102,B=102,A=32))
	Powerup(13)=(Type="Botpack.PAmmo",Color=(R=102,G=102,B=102,A=32))
	// Powerup(14)=(Type="Botpack.MiniAmmo",Color=(R=102,G=102,B=102,A=32))
	Powerup(15)=(Type="Botpack.FlakAmmo",Color=(R=102,G=102,B=102,A=32))
	Powerup(16)=(Type="Botpack.RocketPack",Color=(R=102,G=102,B=102,A=32))
	Powerup(17)=(Type="Botpack.ShockCore",Color=(R=102,G=102,B=102,A=32))
	// Powerup(18)=(Type="Botpack.BulletBox",Color=(R=102,G=102,B=102,A=32))
	//// Not working - I get a second enforcer, rather than my single becoming double!
	// Powerup(19)=(Type="Botpack.DoubleEnforcer",Color=(R=180,G=180,B=180,A=32))
}
