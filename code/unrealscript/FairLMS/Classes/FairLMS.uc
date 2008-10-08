// TODO: We didn't really need to give the player those weapons, since LMS will probably suit them up anyway.
//       But maybe we aren't in the LMS gametype.  In which case, we should probably remove weapons and other pickup items from the map.
// TODO BUG: Were some of the armor+pads getting left invisible on the spawnpoints?  I kept spawning with 150, but maybe that was done by normal LMS.
// TODO: Anti-camper detection.
// TODO: I didn't hear the amp pickup sound (altho maybe it came the same time as "headshot")
// TODO: Sucks to get Armour then Armour again, etc.  :P

class FairLMS expands Mutator config(FairLMS);

var config bool bGiveWeapons;
var config int InitialArmour,InitialHealth;
var config float HealthLostPerSec,HealthGainedPerKill;
var config int FragsForPowerup;
var config bool bGivePowerups;
var config String InitialWeapon[20];
var config Color HealthColor,ArmorColor,JumpBootsColor,DamageAmpColor,InvisibilityColor,ShieldBeltColor,RedeemerColor;
var config Sound PowerupSound;

var int KillsSinceSpawn[64];

// struct LMSBonus { var String Name; var class<Inventory> Type; var Color Color; var Name Sound; }
// Actually each item probably already has a Name available from its defaultproperties.

function PostBeginPlay() {
	Super.PostBeginPlay();
	SetTimer(1,True);
	if (HealthLostPerSec>0)
		Level.Game.GameName = "Anti-Idle "$ Level.Game.GameName;
	if (bGivePowerups || HealthGainedPerKill>0)
		Level.Game.GameName = Level.Game.GameName $" with Frag Bonuses";
	DeathMatchPlus(Level.Game).StartMessage = "Your are losing health!  Kill to stay alive!";
}

event Timer() {
	local PlayerPawn p;
	Super.Timer();
	foreach AllActors(class'PlayerPawn',p) {
		p.Health -= HealthLostPerSec;
		if (p.Health<1)
			p.Health = 1;
		// Average death 10 seconds after health runs out, provided timer stays at 1.0.
		if (p.Health <= 1 && FRand()<0.1) { // TODO: or was hit recently (may be about to be finished off)
			// Level.Game.
			p.Died(None, 'Suicided', p.Location);
		}
		// CONSIDER TODO: when player first reaches 0, we could add some effect to him (skull above his head) to show that he requires only 1 damage hit to die.
		//                maybe fairer not to warn other players, but to warn the player who is in danger!
	}
}

function ModifyPlayer(Pawn p) {
	Super.ModifyPlayer(p);
	p.Health = InitialHealth;
	// p.PlayerReplicationInfo.Armor = InitialArmour;
	GiveAllWeapons(p);
	if (PlayerPawn(p)!=None) {
		KillsSinceSpawn[p.PlayerReplicationInfo.PlayerID%64] = 0;
	}
}

function ScoreKill(Pawn killer, Pawn other) {
	Super.ScoreKill(killer,other);
	if (killer != None) {
		killer.Health += HealthGainedPerKill;
		if (killer.Health > 199) killer.Health = 199;
	}
	if (PlayerPawn(killer)!=None && PlayerPawn(killer).PlayerReplicationInfo!=None) {
		KillsSinceSpawn[killer.PlayerReplicationInfo.PlayerID%64] += 1;
		if (KillsSinceSpawn[killer.PlayerReplicationInfo.PlayerID%64]%FragsForPowerup == 0 && bGivePowerups) {
			GiveRandomPowerup(killer);
		}
	}
}

function GiveAllWeapons(Pawn p) {
	local Inventory Inv;
	local int i;
	local class<Weapon> type;

	// Give appropriate armour.
	// CONSIDER: Alternatively, give them normal armour, but adjust its Charge.
	if (InitialArmour<50) {
	} else if (InitialArmour>=50 && InitialArmour<100) {
		GivePickup(p,class'ThighPads');
	} else if (InitialArmour>=100 && InitialArmour<150) {
		GivePickup(p,class'Armor2');
	} else if (InitialArmour>=150) {
		GivePickup(p,class'Armor2');
		GivePickup(p,class'ThighPads');
	}

	if (bGiveWeapons) {
		for (i=0;i<20;i++) {
			if (InitialWeapon[i]!="") {
				type = class<Weapon>(DynamicLoadObject(InitialWeapon[i],class'class'));
				Inv = p.FindInventoryType(type);
				if (Inv == None) {
					DeathMatchPlus(Level.Game).GiveWeapon(p,InitialWeapon[i]);
				} else {
					Log(Self$".GiveAllWeapons() Warning! "$p.getHumanName()$" already had a "$type$" so re-using it "$Inv);
					// Maybe this is not needed.  My actual problem was adding a SniperRifle to a player that already had a zp_SniperRifle.
				}
			}
		}
	}

}

function Inventory GivePickup(Pawn p, class<Inventory> t) {
	local Inventory Inv;
	Inv = p.FindInventoryType(t);
	if (Inv!=None)
		Log(Self$".GivePickup() Warning! "$p.getHumanName()$" already had a "$t$" so re-using it "$Inv);
	if (Inv==None)
		Inv = Spawn(t);
	if (Inv==None) {
		Log(Self$".GivePickup() Failed to spawn a "$t);
	} else {
		Inv.bHeldItem=True;
		Inv.RespawnTime=0;
		if (Weapon(Inv)!=None && Weapon(Inv).AmmoType!=None) {
			Weapon(Inv).AmmoType.AmmoAmount = Weapon(Inv).AmmoType.default.AmmoAmount * 3;
		}
		Inv.GiveTo(p);
		Inv.Activate();
		if (Inv.PickupSound != None) {
			p.PlaySound(Inv.PickupSound,SLOT_Interface,3.0);
		} else {
			p.PlaySound(PowerupSound,SLOT_Interface,3.0);
		}
	}
	return Inv;
}

function GiveRandomPowerup(Pawn p) {
	local int i;
	local Inventory inv;
	i = 7*FRand();
	// TODO: may as well just put these in lists in the config!
	// TODO: No, be intelligent, give you something you need, or something you haven't already got.
	switch (i) {
		case 0:
			if (p.Health>=100) {
				GiveRandomPowerup(p); return;
			}
			p.Health += 100;
			if (p.Health > 199) p.Health = 199;
			p.PlaySound(Sound'UnrealShare.Pickups.Health2',SLOT_Interface,3.0);
			FlashMessage(p,"Health",HealthColor);
		break;
		case 1:
			inv = p.FindInventoryType(class'Armor2');
			if (inv!=None && Armor2(inv).Charge>=0) {
				GiveRandomPowerup(p); return;
			}
			GivePickup(p,class'Armor2');
			// GivePickup(p,class'ThighPads');
			FlashMessage(p,"Armor",ArmorColor);
		break;
		case 2:
			GivePickup(p,class'UT_JumpBoots');
			FlashMessage(p,"Jump Boots",JumpBootsColor);
		break;
		case 3:
			GivePickup(p,class'UDamage');
			FlashMessage(p,"Damage Amp",DamageAmpColor);
		break;
		case 4:
			GivePickup(p,class'UT_Stealth');
			FlashMessage(p,"Invisibility",InvisibilityColor);
			// TODO: Appears to play no sound.
		break;
		case 5:
			GivePickup(p,class'UT_ShieldBelt');
			FlashMessage(p,"Shield Belt",ShieldBeltColor);
		break;
		case 6:
			// DONE: Worked up until firing, but then there was no projectile.  However summoning one worked fine.
			inv = GivePickup(p,class'WarheadLauncher');
			Weapon(inv).AmmoType.AmmoAmount = 1;
			FlashMessage(p,"Redeemer",RedeemerColor);
			// DONE: can they get a second warhead?
		break;
	}
}

function FlashMessage(Pawn p, String msg, Color col) {
	if (PlayerPawn(p)==None)
		return;
	// msg = Caps(msg) $ "!";
	msg = "-+- "$ Caps(msg) $" -+-";
	PlayerPawn(p).ClearProgressMessages();
	PlayerPawn(p).SetProgressTime(3.0);
	PlayerPawn(p).SetProgressColor(col,4);
	PlayerPawn(p).SetProgressMessage(msg,4);
}

function Mutate(String msg, PlayerPawn Sender) {
	local String rep;
	local Inventory inv;
	if (msg ~= "LISTINV") {
		rep = "";
		for (Inv=Sender.Inventory; Inv!=None; Inv=Inv.Inventory) {
			// rep = rep $ Inv $"("$ Inv.getHumanName() $") ";
			rep = rep $ Inv $" ";
			if (Len(rep)>1200)
				break;
		}
		Sender.ClientMessage("Your inventory: "$rep);
	}
	Super.Mutate(msg,Sender);
}

defaultproperties {
	bGiveWeapons=False  // Handled by LMS
	InitialArmour=0     // Handled by LMS
	InitialHealth=100
	// InitialArmour=100
	HealthLostPerSec=2.0
	HealthGainedPerKill=50.0
	bGivePowerups=True
	FragsForPowerup=4
	InitialWeapon(0)="Botpack.ImpactHammer"
	InitialWeapon(1)="Botpack.Enforcer"
	InitialWeapon(2)="Botpack.UT_BioRifle"
	InitialWeapon(3)="Botpack.PulseGun"
	InitialWeapon(4)="Botpack.Minigun2"
	InitialWeapon(5)="Botpack.UT_FlakCannon"
	InitialWeapon(6)="Botpack.UT_EightBall"
	InitialWeapon(7)="Botpack.ShockRifle"
	InitialWeapon(8)="Botpack.SniperRifle"
	HealthColor=(R=91,G=255,B=91,A=30)
	ArmorColor=(R=255,G=173,B=91,A=30)
	JumpBootsColor=(R=91,G=255,B=255,A=30)
	DamageAmpColor=(R=255,G=91,B=255,A=30)
	InvisibilityColor=(R=91,G=91,B=255,A=30)
	ShieldBeltColor=(R=255,G=255,B=91,A=30)
	RedeemerColor=(R=255,G=91,B=91,A=30)
	PowerupSound=Sound'Botpack.Pickups.BeltSnd'
	// PowerupSound=Sound'Botpack.Pickups.Sbelthe2'
	// PowerupSound=Sound'Botpack.Pickups.AmpOut'
}

