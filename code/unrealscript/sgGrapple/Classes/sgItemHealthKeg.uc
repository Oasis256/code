/* WARNING! This file was auto-generated by jpp.  You probably want to be editing ./sgItemHealthKeg.uc.jpp instead. */


class sgItemHealthKeg extends sgaItem;

simulated function PostBeginPlay() {
 Super.PostBeginPlay();
 InventoryType = String(class'HealthPack');
}

simulated function OnGive(Pawn Target, Inventory Inv) {
 if (Grade >= 0.1) {
  HealthPack(Inv).HealingAmount = FClamp(100+Grade*100,100,200);
 }
}

defaultproperties {
 // InventoryType="kxDoubleJump.DoubleJumpBoots"
 // InventoryClass=class'kxDoubleJump.DoubleJumpBoots'
 BuildingName="Health Keg"
 BuildCost=100
 UpgradeCost=20
 Model=LodMesh'Botpack.hbox'
}
