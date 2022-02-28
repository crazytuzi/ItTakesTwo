import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchSettings;
import Peanuts.Audio.AudioStatics;

event void FOnNutScrewed();

class AWrenchNutActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NutRoot;

	UPROPERTY(DefaultComponent, Attach = NutRoot)
	USceneComponent AttachSocket;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PreviewRoot;

	FMagneticWrenchSettings Settings;

	UPROPERTY()
	FOnNutScrewed OnNutScrewed;

	UPROPERTY(Category = "Screwing")
	bool bIsFullyScrewed = false;

	UPROPERTY(Category = "Screwing")
	float ScrewGoal = 900.f;

	UPROPERTY(Category = "Screwing")
	float ScrewLocationOffset = 500.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkCompNut;

	float CurrentNutRotation = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		FTransform DeltaTransform;
		DeltaTransform.Rotation = FQuat(FVector::UpVector, FMath::DegreesToRadians(ScrewGoal));
		DeltaTransform.Location = -FVector::UpVector * ScrewLocationOffset;

		PreviewRoot.SetRelativeTransform(DeltaTransform);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void SetNutRotation(float Rotation)
	{
		float ClampedRotation = FMath::Clamp(Rotation, 0.f, ScrewGoal);
		CurrentNutRotation = ClampedRotation;

		FTransform DeltaTransform;
		DeltaTransform.Rotation = FQuat(FVector::UpVector, FMath::DegreesToRadians(ClampedRotation));
		DeltaTransform.Location = -FVector::UpVector * (ClampedRotation / ScrewGoal) * ScrewLocationOffset;

		NutRoot.SetRelativeTransform(DeltaTransform);
	}

	void CompleteScrew()
	{
		if (bIsFullyScrewed)
			return;

		SetNutRotation(ScrewGoal);

		bIsFullyScrewed = true;
		DisableCollisionOnComponentAndChildren(NutRoot);
	//	SetActorEnableCollision(false);
		OnNutScrewed.Broadcast();
	}

	UFUNCTION()
	void SnapFullyScrewed()
	{
		SetNutRotation(ScrewGoal);

		bIsFullyScrewed = true;
		DisableCollisionOnComponentAndChildren(NutRoot);
	//	SetActorEnableCollision(false);

		BP_OnSnapFullyScrewed();
	}

	UFUNCTION()
	void DisableCollisionOnComponentAndChildren(USceneComponent Component)
	{
		TArray<USceneComponent> Children;
		Component.GetChildrenComponents(true, Children);
		for (auto Child : Children)
		{
			auto PrimitiveChild = Cast<UPrimitiveComponent>(Child);
			if (PrimitiveChild != nullptr)
				PrimitiveChild.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartTurning()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_StopTurning()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_WrenchInPlace()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnSnapFullyScrewed()
	{
		
	}

	UFUNCTION(BlueprintPure)
	float GetNutScrewedPercent()
	{
		return CurrentNutRotation / ScrewGoal;
	}
}