import Cake.LevelSpecific.SnowGlobe.Magnetic.Wheel.MagneticWheelFlapActor;

event void FOnMagneticWheelSpinningStateChanged(bool IsSpinning);
event void FOnMagneticWheelReachedMaxRotation();
event void FOnMagneticWheelBackToStart();

UCLASS(Abstract)
class AMagneticWheelActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent, Attach = Base)
	UStaticMeshComponent Mesh;
	
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncProgress;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncVelocity;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncRotationComp;

	UPROPERTY()
	TArray<AMagneticWheelFlapActor> WheelFlaps;

	TArray<UMagnetGenericComponent> ActiveMagneticComponents;
	
	UPROPERTY()
	EHazePlayer ControlsideToControlWeel;

	float AddedRotation = 0.0f;

	UPROPERTY()
	float CurrentVelocity;

	UPROPERTY()
	float Progress = 0; 
	
	UPROPERTY()
	UMagneticWheelSettingsDataAsset WheelSettings;

	UPROPERTY()
	FOnMagneticWheelSpinningStateChanged OnMagneticWheelSpinningStateChanged;
	UPROPERTY()
 	FOnMagneticWheelReachedMaxRotation OnMagneticWheelReachedMaxRotation;
	UPROPERTY()
	FOnMagneticWheelBackToStart OnMagneticWheelBackToStart;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ControlsideToControlWeel == EHazePlayer::May)
		{
			SetControlSide(Game::GetMay());
		}
		else
		{
			SetControlSide(Game::GetCody());
		}

		
		AddCapability(n"MagneticWheelCapability");

		TArray<AActor> ActorArray;
		this.GetAttachedActors(ActorArray);
		for (AActor Actor : ActorArray)
		{
			AMagneticWheelFlapActor Flap = Cast<AMagneticWheelFlapActor>(Actor);
			if (Flap != nullptr)
			{
				if(!WheelFlaps.Contains(Flap))
					WheelFlaps.Add(Flap);
			}
		}

		for(AMagneticWheelFlapActor Flap : WheelFlaps)
		{
			UMagnetGenericComponent MagComp = UMagnetGenericComponent::Get(Flap);

			if(MagComp != nullptr)
			{
				MagComp.OnGenericMagnetInteractionStateChanged.AddUFunction(this, n"WheelFlapStateChanged");
			}

			Flap.AttachToComponent(Base, NAME_None, EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION()
	void WheelFlapStateChanged(bool Active, UMagnetGenericComponent Component, AHazePlayerCharacter Player)
	{
		if(Active)
		{
			ActiveMagneticComponents.Add(Component);
		}
		else
		{
			ActiveMagneticComponents.Remove(Component);
		}
	}
}


class UMagneticWheelSettingsDataAsset : UDataAsset
{
	UPROPERTY()
	float Drag = 2.3f;
	UPROPERTY()
	float Acceleration = 0.7f;
	UPROPERTY()
	bool bSpinBack = false;
	UPROPERTY()
	float SpinBackSpeed = 100.0f;
	UPROPERTY()
	bool bCannotBeSpunBelowMinRotation = false;
	UPROPERTY()
	float MinRotation = -50.0f;
	UPROPERTY()
	bool bHasMaxRotation = false;
	UPROPERTY()
	float MaxRotation = 500.0f;
	UPROPERTY()
	bool bStayAtMax = false;
}