import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomActivationPoints;
class ULightRoomLightStripComponent : UStaticMeshComponent
{
	UPROPERTY()
	ALightRoomActivationPoints ActivationPoint;

	UPROPERTY()
	FLinearColor Black;

	UPROPERTY()
	FLinearColor Blue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActivationPoint.ActivationPointLightProgress.AddUFunction(this, n"AcitvationProgress");
	}

	UFUNCTION()
	void AcitvationProgress(float Progress)
	{
		SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black * (1.f - Progress) + Blue * Progress);
	}
}