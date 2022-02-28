import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Capabilities.CameraTags;

class UTreeBoatChaseCameraCapability : UHazeCapability
{
UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::ChaseAssistance);

	default TickGroup = ECapabilityTickGroups::GamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	float NoInputDuration = BIG_NUMBER;
	float MovementDuration = 0.f;
	float AccelerationDuration = 5.f;
	float MovementInputDelay = 0.2f;
	FVector PreviousLocation; 
	FVector DeltaMove;
	AHazeActor Boat; 
	FHazeAcceleratedRotator ChaseRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (User == nullptr)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (User == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AHazeActor CurrentBoat = Cast<AHazeActor>(GetAttributeObject(n"Boat"));

		if(CurrentBoat != Boat)
		{
			Boat = CurrentBoat; 
			PreviousLocation = Boat.GetActorLocation();
		}

		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);
		ChaseRotation.SnapTo(GetTargetRotation());
		SetMutuallyExclusive(CameraTags::ChaseAssistance, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);
		SetMutuallyExclusive(CameraTags::ChaseAssistance, false);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Boat == nullptr)
			return;
		if(DeltaTime < 0.001)
			return; 
		DeltaMove = Boat.GetActorLocation() - PreviousLocation; 
		PreviousLocation = Boat.GetActorLocation();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Ignore on remote side; control rotation is replicated
		if(!HasControl())
			return;
	
		FVector DebugDeltaMove = Boat.GetActorLocation() - PreviousLocation; 
		PrintToScreen("CodyPitch " + Boat + DebugDeltaMove);
		PreviousLocation = Boat.GetActorLocation();
		
		float TimeDilation = PlayerUser.GetActorTimeDilation();
		float RealTimeDeltaSeconds = (TimeDilation > 0.f) ? DeltaTime / TimeDilation : 1.f;
		UpdateInputDuration(RealTimeDeltaSeconds);
		if (NoInputDuration <= MovementInputDelay)	
		{
			ChaseRotation.Velocity = 0.f;
			return;
		}


		FRotator DesiredRot = User.DesiredRotation;
		FRotator TargetRot = GetTargetRotation(); 
		TargetRot.Roll = 0.f;

		ChaseRotation.Value = DesiredRot; // This value is expected to be changed by outside systems
		if (MovementDuration > MovementInputDelay)
		{
			ChaseRotation.AccelerateTo(TargetRot, AccelerationDuration, DeltaTime);
		}
		else
		{
			// Allow velocity to decelerate to 0
			ChaseRotation.Velocity -= ChaseRotation.Velocity * 10.f * DeltaTime;
			ChaseRotation.Value += ChaseRotation.Velocity * DeltaTime;
		}
		
		FRotator DeltaRot = (ChaseRotation.Value - DesiredRot).GetNormalized();
	 	
		User.AddDesiredRotation(DeltaRot);
	}

	void UpdateInputDuration(float DeltaTime)
	{
		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
		if (AxisInput.IsNearlyZero(0.001f))
			NoInputDuration += DeltaTime;
		else
			NoInputDuration = 0.f;

		if (IsMoving())
			MovementDuration += DeltaTime;
		else
			MovementDuration = 0.f;
	}

	FRotator GetTargetRotation()
	{
		FRotator OwnerRotation = Owner.GetActorRotation();
		float Yaw = OwnerRotation.Yaw - 180; 
		
		//To rows below enables velocity
		//if(!DeltaMove.IsNearlyZero())
			//Yaw = DeltaMove.Rotation().Yaw;
		return FRotator(-OwnerRotation.Pitch ,Yaw, 0);
	}

	bool IsMoving()
	{
		//const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
		//return !AxisInput.IsNearlyZero(0.01f);
		return PlayerUser.GetActualVelocity().SizeSquared2D() > 0.001f;
	}
};

