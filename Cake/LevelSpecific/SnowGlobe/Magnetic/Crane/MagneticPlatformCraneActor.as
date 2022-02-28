import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

UCLASS(Abstract)
class AMagneticPlatformCraneActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	USceneComponent RotatingBase;

	UPROPERTY(DefaultComponent, Attach = RotatingBase)
	UStaticMeshComponent TopMesh;

	UPROPERTY(DefaultComponent, Attach = RotatingBase)
	USceneComponent LiftBase;

	UPROPERTY(DefaultComponent, Attach = LiftBase)
	UStaticMeshComponent MagneticSteer;

	UPROPERTY(DefaultComponent, Attach = MagneticSteer)
	UMagnetGenericComponent MagnetComponent;

	UPROPERTY(DefaultComponent, Attach = LiftBase)
	UStaticMeshComponent LiftMesh;

	UPROPERTY(DefaultComponent, Attach = RotatingBase)
	USceneComponent PointOfInterest;

	UPROPERTY(DefaultComponent, Attach = LiftBase)
	USceneComponent RopeAttachmentPoint;

	UPROPERTY(DefaultComponent, Attach = RotatingBase)
	USceneComponent RopePoint;

	UPROPERTY(DefaultComponent, Attach = RopePoint)
	UStaticMeshComponent Platform;
	
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent RotationSync;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface RedMaterial;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlueMaterial;

	UPROPERTY()
	bool bIsPositive;

	UPROPERTY()
	EHazePlayer OwningPlayer;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bIsPositive)
		{
			MagneticSteer.SetMaterial(0, RedMaterial);
			MagnetComponent.Polarity = EMagnetPolarity::Plus_Red;
		}
		else
		{
			MagneticSteer.SetMaterial(0, BlueMaterial);
			MagnetComponent.Polarity = EMagnetPolarity::Minus_Blue;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (OwningPlayer == EHazePlayer::Cody)
		{
			SetControlSide(Game::GetCody());
		}
		else
		{
			SetControlSide(Game::GetMay());
		}

		AddCapability(n"MagneticCraneHorizontalAimCapability");
		// MagneticComponent.HorizontalAimComponent = RotatingBase;
		// MagneticComponent.VerticalAimComponent = LiftBase;
		// MagneticComponent.PointOfInterestComponent = PointOfInterest;
	}


	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		if(RopePoint.WorldLocation != RopeAttachmentPoint.WorldLocation)
		{
			RopePoint.SetWorldLocation(RopeAttachmentPoint.WorldLocation);
		}
	}
}