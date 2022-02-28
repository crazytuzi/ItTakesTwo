import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuck;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuckComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPaddle;

class UHockeyPuckMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPuckMovementCapability");

	default CapabilityDebugCategory = n"Gameplay";
	default CapabilityDebugCategory = n"AirHockey";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHockeyPuck HockeyPuck;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	UHockeyPuckComponent HockeyPuckComp;

	float Drag = 0.2f;
	float ReboundVelocityDivider = 0.93f;
	float PuckGravity = 142000.f;

	FVector Velocity;

	bool bIsTurningLeft;
	int RotationDirection;

	float RotationSpeed;
	float RotationSpeedDivider = 13.5f;

	float CollideMovingObjAddedSpeed;

	float SlopeSpeed = 1050.f;

	float ImpulseMultiplier = 1.f;

	FHazeAcceleratedFloat YawAccelerated;
	FHazeAcceleratedRotator SlopeRotationAccelerated;

	FQuat Rotation;
	FQuat PrevRotation;

	FName Tag = n"HockeyPuck";

	FVector PreMoveVelocity;

	float NetworkRate = 0.1f;
	float NetworkNewTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HockeyPuck = Cast<AHockeyPuck>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);
		HockeyPuckComp = UHockeyPuckComponent::Get(Owner);

		HockeyPuck.AddActorTag(Tag);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (HockeyPuck == nullptr)
        	return EHazeNetworkActivation::DontActivate;
		
		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//To initiate net values
		HockeyPuck.OtherSidePosition = HockeyPuck.ActorLocation;
		HockeyPuck.OtherVelocity = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.CanCalculateMovement())
		{	
			HockeyPuck.CurrentVelocity *= 1.00035f;
			
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"TurtleMove");
			CalculateMovement(FrameMove, DeltaTime);
			MoveComp.Move(FrameMove);

			// NetworkControl(DeltaTime);		
		}	
	}	

	UFUNCTION()
	void CalculateMovement(FHazeFrameMovement& FrameMove, float DeltaTime)
	{
		if (HockeyPuck.CurrentVelocity.Size() >= HockeyPuck.MinSpeed)
			HockeyPuck.CurrentVelocity -= HockeyPuck.CurrentVelocity * Drag * DeltaTime;

		HockeyPuck.CurrentVelocity = GetCollisionReflectedVelocity(HockeyPuck.CurrentVelocity);
		
		if (MoveComp.IsAirborne())
		{
		 	HockeyPuck.CurrentVelocity.Z -= 7000.f * DeltaTime; 	
		} 

		FrameMove.ApplyVelocity(HockeyPuck.CurrentVelocity);
	}

	FVector GetCollisionReflectedVelocity(FVector Velocity)
	{
		FVector _Velocity = Velocity;

		if (MoveComp.ForwardHit.bBlockingHit)
		{
			FVector ImpactPoint = MoveComp.ForwardHit.ImpactPoint;
			FVector Normal = Owner.ActorLocation - ImpactPoint;
			Normal = Normal.ConstrainToPlane(FVector::UpVector);
			Normal.Normalize();

			AHockeyPaddle HockeyPaddle = Cast<AHockeyPaddle>(MoveComp.ForwardHit.Actor);

			if (HockeyPaddle == nullptr)
				return _Velocity = FMath::GetReflectionVector(_Velocity, Normal);


			// _Velocity += HockeyPaddle.MoveComp.Velocity;
			
			FVector VelocityDirectionToAdd = HockeyPaddle.MoveComp.Velocity.ConstrainToDirection(Normal);
			
			_Velocity = FMath::GetReflectionVector(_Velocity, Normal);
			_Velocity += VelocityDirectionToAdd * 1.3f;

			// float AdditionAmount = _Velocity.Size() / HockeyPaddle.MoveComp.Velocity.Size();
			// float Multiplier = 1 + AdditionAmount;

			// _Velocity *= Multiplier;
			
			if (_Velocity.Size() >= HockeyPuck.MaxSpeed)
				return _Velocity.GetClampedToMaxSize(HockeyPuck.MaxSpeed);
			else
				return _Velocity;
		}

		return _Velocity;
	}

	// UFUNCTION()
	// void NetworkControl(float DeltaTime)
	// {
	// 	if (HockeyPuck.bShouldNetwork && Network::IsNetworked())
	// 	{
	// 		if (NetworkNewTime <= System::GameTimeInSeconds)
	// 		{
	// 			NetworkNewTime = System::GameTimeInSeconds + NetworkRate;
	// 			NetOtherSidePosition(HasControl(), HockeyPuck.ActorLocation, MoveComp.Velocity);
	// 		}
	// 	}
	// }

	// UFUNCTION(NetFunction)
	// void NetOtherSidePosition(bool bControlSide, FVector OtherPosition, FVector OtherVelocity)
	// {
	// 	if (HasControl() == bControlSide)
	// 		return;

	// 	HockeyPuck.OtherSidePosition = OtherPosition;
	// 	HockeyPuck.OtherVelocity = OtherVelocity;
	// }
}