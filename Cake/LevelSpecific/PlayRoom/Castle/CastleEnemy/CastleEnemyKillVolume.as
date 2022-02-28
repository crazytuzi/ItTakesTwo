import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

import void RegisterEnemyKillVolume(ACastleEnemyKillVolume Volume) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList";
import void UnregisterEnemyKillVolume(ACastleEnemyKillVolume Volume) from "Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleEnemyList";

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class ACastleEnemyKillVolume : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor::Red);

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RegisterEnemyKillVolume(this);
	}

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		UnregisterEnemyKillVolume(this);
	}
}