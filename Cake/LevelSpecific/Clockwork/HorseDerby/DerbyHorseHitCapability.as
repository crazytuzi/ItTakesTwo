import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;

class UDerbyHorseHitCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorse");
	default CapabilityTags.Add(n"DerbyHorseMovement");
	default CapabilityTags.Add(n"DerbyHorseHitCapability");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	ADerbyHorseActor HorseActor;
	UHazeSplineFollowComponent SplineFollowComp;
	UHazeSplineComponent SplineComp;
	UDerbyHorseComponent HorseComp;
	AHorseDerbyManager Manager;
	
	float PushBackDistance = 300.f;
	float PushBackSpeed = 1000.f;
	float TargetDistance = 0.f;

	float CountdownTime = 0.f;
	float CountdownTimer = 0.f;

	FHazeAcceleratedFloat Speed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		HorseComp = HorseActor.HorseComponent;
		Manager = Cast<AHorseDerbyManager>(GetAttributeObject(n"Manager"));

		SplineFollowComp = HorseActor.SplineFollowComp;
		SplineComp = HorseActor.SplineTrack.SplineComp;

		CountdownTime = HorseActor.HitDisableTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HorseActor.InteractingPlayer != nullptr && HorseActor.Collided)
			return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HorseActor.Collided || HorseActor.HorseState == EDerbyHorseState::GameWon)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		if (HorseActor.HorseDerbyCollideState == EHorseDerbyCollideState::RaceComplete)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(!SplineFollowComp.HasActiveSpline())
			SplineFollowComp.ActivateSplineMovement(SplineComp, true);

		HorseComp.MovementState = EDerbyHorseMovementState::Hit;
		HorseActor.SetAnimBoolParam(n"Hit", true);

		CountdownTimer = 0.f;
		TranslationFinished = false;

		SetMutuallyExclusive(n"DerbyHorseMovement", true);
		HorseActor.SetCapabilityActionState(n"Hit", EHazeActionState::Active);
		
		HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);

		HorseActor.BlockCapabilities(n"DerbyHorseJump", this);
		HorseActor.BlockCapabilities(n"DerbyHorseCrouch", this);

		HorseActor.HitRumble();

		CalculateEndDistance();

		Speed.Value = PushBackSpeed;

		if (HorseActor.InteractingPlayer != nullptr)
			Manager.HitByObstacles[HorseActor.InteractingPlayer]++;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"DerbyHorseMovement", false);

		HorseActor.UnblockCapabilities(n"DerbyHorseCrouch", this);
		HorseActor.UnblockCapabilities(n"DerbyHorseJump", this);
		
		HorseActor.SetCapabilityActionState(n"Hit" , EHazeActionState::Inactive);

		HorseActor.Collided = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveBack(DeltaTime);
		CountDownActiveTime(DeltaTime);
	}

	void CalculateEndDistance()
	{
		float CurrentDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(HorseActor.ActorLocation);
		TargetDistance = CurrentDistance - PushBackDistance;
		
		float MinimumDistance = HorseActor.SplineTrack.GetSplineDistanceAtGamePosition(EDerbyHorseState::Inactive);

		if(TargetDistance < MinimumDistance)
			TargetDistance = MinimumDistance;
	}

	void MoveBack(float DeltaTime)
	{
		FHazeSplineSystemPosition SystemPosition;

		float CurrentDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(SplineFollowComp.Position.WorldLocation);
		//float PredictedDistance = CurrentDistance - (PushBackSpeed * DeltaTime);

		Speed.AccelerateTo(100, 0.5f, DeltaTime);

		float PredictedDistance = CurrentDistance - (Speed.Value * DeltaTime);

		if(PredictedDistance > TargetDistance)
		{
			SplineFollowComp.UpdateSplineMovement((-PushBackSpeed * DeltaTime), SystemPosition);
		}
		else
		{
			SplineFollowComp.UpdateSplineMovement(SplineComp.GetLocationAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World), SystemPosition);
			//HorseActor.Collided = false;
			TranslationFinished = true;
		}

		HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
	}

	bool TranslationFinished = false;
	void CountDownActiveTime(float DeltaTime)
	{
		CountdownTimer += DeltaTime;

		if(CountdownTimer >= CountdownTime && TranslationFinished)
			HorseActor.Collided = false;
	}
}