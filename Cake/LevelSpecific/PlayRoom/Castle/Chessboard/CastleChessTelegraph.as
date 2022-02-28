import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

class ACastleChessTelegraph : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TelegraphPlane;
	default TelegraphPlane.SetRelativeLocation(FVector(0, 0, 1.f));
	default TelegraphPlane.SetRelativeScale3D(FVector(3,3,3));
	default TelegraphPlane.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY()
	TArray<AHazePlayerCharacter> OverlappingPlayers;

	TPerPlayer<float> DamageTickTimer;
	
	UPROPERTY()
	float Opacity = 0.75f;
	UPROPERTY()
	float Size = 1;
	UPROPERTY()
	FLinearColor AlbedoColor = FLinearColor::Red;

	UPROPERTY()
	float Duration = 3.f;
	float DurationCurrent = 0.f;

	UMaterialInstanceDynamic MaterialInstance;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif	

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		TelegraphPlane.SetScalarParameterValueOnMaterialIndex(0, n"Opacity", Opacity);
		TelegraphPlane.SetScalarParameterValueOnMaterialIndex(0, n"Size", Size);
		TelegraphPlane.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", AlbedoColor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateDuration(DeltaTime);		
	}

	void UpdateDuration(float DeltaTime)
	{
		DurationCurrent += DeltaTime;

		if (DurationCurrent >= Duration)
			DestroyActor();
	}
}