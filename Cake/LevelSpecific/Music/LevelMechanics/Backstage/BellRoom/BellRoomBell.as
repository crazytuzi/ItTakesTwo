import Cake.LevelSpecific.Music.LevelMechanics.Bell.Bell;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BellRoom.BellRoomStatics;

event void FBellRoomBellSignature(EBellTone BellTone);

class ABellRoomBell : ABell
{
	UPROPERTY()
	FBellRoomBellSignature BellRoomBellRung;
	
	UPROPERTY()
	EBellTone BellTone;

	UPROPERTY()
	TArray<UMaterialInterface> MaterialArray;

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		Super::CymbalHit(HitInfo);
		BellRoomBellRung.Broadcast(BellTone);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		BellMesh.SetMaterial(0, MaterialArray[BellTone]);
	}
}