import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Capabilities.CameraTags;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.OctopusBoss.PirateOctopusActor;
import Vino.Camera.Settings.CameraVehicleChaseSettings;

class UCameraWheelBoatChaseCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;
	UOnWheelBoatComponent WheelBoatComp;

	APirateOctopusActor BossActor;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");

	default CapabilityTags.Add(CameraTags::VehicleChaseAssistance);

	default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	float NoInputDuration = BIG_NUMBER;
	FHazeAcceleratedRotator ChaseRotation;
	FHazeAcceleratedRotator POIChaseRotation;
	FHazeAcceleratedFloat AccelerationDuration;

	bool bLastInputWasCamera = false;

	float CameraInputDelay = 0.1f;
	float MovementInputDelay = 0.1f;
	float AccelerationDurationTargetDefault = 3.f;
	float AccelerationDurationTargetBoss = 0.1f;	
	float AccelerationDurationTargetBossWithPOI = 2.f;

	bool bPointOfInterestActive;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		WheelBoatComp = UOnWheelBoatComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(User.GetCurrentCamera() == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(WheelBoatComp.WheelBoat.UseBossFightMovement() && WheelBoatComp.WheelBoat.IsInStream())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if(User.GetCurrentCamera() == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if(WheelBoatComp.WheelBoat.UseBossFightMovement() && WheelBoatComp.WheelBoat.IsInStream())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// if (User != nullptr)
		// 	User.RegisterDesiredRotationReplication(this);
		ChaseRotation.SnapTo(GetTargetRotation());
		SetMutuallyExclusive(CameraTags::VehicleChaseAssistance, true);
		Owner.BlockCapabilities(CameraTags::ChaseAssistance, this);
		WheelBoatComp.WheelBoat.OnSetPOIEvent.AddUFunction(this, n"SetAcceleratedPOI");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// if (User != nullptr)
		// 	User.UnregisterDesiredRotationReplication(this);
		SetMutuallyExclusive(CameraTags::VehicleChaseAssistance, false);
		Owner.UnblockCapabilities(CameraTags::ChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) 
	{
		UCameraVehicleChaseSettings Settings = User.VehicleChaseSettings;
		if (Settings == nullptr)
			return;

		float TimeDilation = PlayerUser.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
	
		if(WheelBoatComp.bInBossFight && BossActor == nullptr)
		{
			if(WheelBoatComp.WheelBoat.OctopusBoss != nullptr)
			{
				BossActor = Cast<APirateOctopusActor>(WheelBoatComp.WheelBoat.OctopusBoss);
			}
		}	

		if (NoInputDuration <= Settings.CameraInputDelay)	
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}

		// If the last input we did was camera, and we haven't touched the move stick
		// since then, then we should not do chase until we start applying movement again
		// if (bLastInputWasCamera && Settings.bOnlyChaseAfterMovementInput)
		// {
		// 	ChaseRotation.Velocity = 0.f;
		// 	return;
		// }

		FTransform ChaseTransform;
		ChaseTransform = Owner.RootComponent.WorldTransform;

		// We want to chase towards the camera-parents forward
		TSubclassOf<UHazeCameraParentComponent> ParentClass(UCameraSpringArmComponent::StaticClass());
		UHazeCameraParentComponent Parent = User.GetCurrentCameraParent(ParentClass);

		if (Parent != nullptr)
		{
			// Since the parent might be the thing we're rotating, we want to get its transform _without_ rotation
			FTransform RelativeTransform = Parent.RelativeTransform;
			RelativeTransform.Rotation = FQuat::Identity;

			if (Parent.AttachParent != nullptr)
				ChaseTransform = Parent.AttachParent.GetWorldTransform();

			ChaseTransform = ChaseTransform * RelativeTransform;
		}

		FRotator DesiredRot = User.DesiredRotation;
		FRotator TargetRot = ChaseTransform.Rotation.Rotator();
		TargetRot.Roll = 0.f;

		float TotalAccelerationDuration;

		if(WheelBoatComp.bInBossFight)
		{
			if(BossActor != nullptr && BossActor.GetActiveArmsCount() > 0)
			{
				TotalAccelerationDuration = AccelerationDurationTargetBossWithPOI;		
			}
			else
			{
				TotalAccelerationDuration = AccelerationDurationTargetBoss;
			}
		}
		else
			TotalAccelerationDuration = AccelerationDurationTargetDefault;			

		AccelerationDuration.AccelerateTo(TotalAccelerationDuration, 1.5f, RealTimeDeltaSeconds);

		ChaseRotation.Value = DesiredRot; // This value is expected to be changed by outside systems
		if (SettingsAllowChaseCamera())
		{
			ChaseRotation.AccelerateTo(TargetRot, AccelerationDuration.Value, DeltaTime);
		}
		else
		{
			// Allow velocity to decelerate to 0
			ChaseRotation.Velocity -= ChaseRotation.Velocity * 10.f * DeltaTime;
			ChaseRotation.Value += ChaseRotation.Velocity * DeltaTime;
		}
		
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRot).GetNormalized();
	 	
		FVector POILocation;

		if (bPointOfInterestActive)
		{
			POILocation = WheelBoatComp.WheelBoat.PointOfInterestLoc;
			FVector Direction = (POILocation - WheelBoatComp.WheelBoat.ActorLocation);
			Direction.Normalize();
			FRotator MakeCamRot = FRotator::MakeFromX(Direction);
			POIChaseRotation.AccelerateTo(MakeCamRot, 2.5f, DeltaTime);
			
			User.SetDesiredRotation(POIChaseRotation.Value);
		}
		else
		{
			User.AddDesiredRotation(DeltaRot);
		}
	}

	UFUNCTION()
	void SetAcceleratedPOI(float Time)
	{
		POIChaseRotation.SnapTo(User.DesiredRotation);
		bPointOfInterestActive = true;

		System::SetTimer(this, n"DeactivateSpecialPOI", Time, false);
	}

	UFUNCTION()
	void DeactivateSpecialPOI()
	{
		bPointOfInterestActive = false;
	}

	FRotator GetTargetRotation()
	{
		return Owner.GetActorRotation();
	}

	bool IsMoving()
	{
		return WheelBoatComp.WheelBoat.GetActualVelocity().SizeSquared2D() > 0.001f;
	}

	bool SettingsAllowChaseCamera()
	{
		FHazeCameraSettings Settings;
		User.GetCameraSettings(Settings);
		Settings.Override(User.GetCurrentCamera().Settings);
		if (!Settings.bAllowChaseCamera)
			return false;		

		return true;
	}
};