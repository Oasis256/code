/* WARNING! This file was auto-generated by jpp.  You probably want to be editing ./sgItemForceGun.uc.jpp instead. */


class sgItemForceGun extends sgaItem;

// TODO/CHECK: Due to its expense and usefulness, the ForceGun should drop when
// player is killed, for teammate or for enemy.  This may be better handled in
// the item class.  The problem is, I want that in Siege games, but there's no
// point in GrapplingCTF games, since everyone has one!

simulated function PostBeginPlay() {
 Super.PostBeginPlay();
 InventoryType = String(class'ForceGun');
}

simulated function OnGive(Pawn Target, Inventory Inv) {
 // The default seemed too powerful for a live game, so I halved it.
 ForceGun(Inv).PullStrength = ForceGun(Inv).PullStrength * (0.1 + 0.9*Grade/5) / 2;
}

defaultproperties {
 // InventoryType="kxForceGun.ForceGun"
 // InventoryClass=class'kxForceGun.ForceGun'
 BuildingName="Force Gun"
 BuildCost=1500
 UpgradeCost=50
 Model=LodMesh'Botpack.ImpPick'
}