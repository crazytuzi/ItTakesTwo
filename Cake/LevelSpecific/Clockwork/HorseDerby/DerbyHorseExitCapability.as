import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;
import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseComponent;

class UDerbyHorseExitCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorse");
	default CapabilityTags.Add(n"DerbyHorseMovement");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ADerbyHorseActor HorseActor;
	AHorseDerbyManager Manager;
	UHazeSplineComponent SplineComp;
	UHazeSplineFollowComponent SplineFollowComp;
	UDerbyHorseComponent HorseComp;

	float MovementSpeed = 0.f;

	bool bClearedSettings;

	bool bHaveReachedPos;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		HorseComp = UDerbyHorseComponent::Get(Owner);
		Manager = Cast<AHorseDerbyManager>(GetAttributeObject(n"Manager"));
		SplineFollowComp = HorseActor.SplineFollowComp;
		SplineComp = HorseActor.SplineTrack.SplineComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HorseActor.InteractingPlayer == nullptr && HorseActor.HorseState == EDerbyHorseState::Travelling)
			return EHazeNetworkActivation::ActivateFromControl;

		if(HorseActor.InteractingPlayer == nullptr && HorseActor.HorseState == EDerbyHorseState::GameWon)
			return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HorseActor.InteractingPlayer != nullptr || HorseActor.HorseState == EDerbyHorseState::Inactive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(!SplineFollowComp.HasActiveSpline())
			SplineFollowComp.ActivateSplineMovement(SplineComp, true);

		bHaveReachedPos = false;

		MovementSpeed = Manager.GameInactiveHorseSpeed;

		HorseComp.MovementState = EDerbyHorseMovementState::Trot;

		bClearedSettings = false;

		HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Hit", EHazeActionState::Inactive);
		
		if (HorseActor.TargetPlayer == EHazePlayer::May)
			Manager.LeftInteraction.Disable(n"HorseTransitioning");
		else
			Manager.RightInteraction.Disable(n"HorseTransitioning");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SplineFollowComp.DeactivateSplineMovement();

		HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);
		HorseActor.SetCapabilityActionState(n"Hit", EHazeActionState::Inactive);

		if (HorseActor.TargetPlayer == EHazePlayer::May)
			Manager.LeftInteraction.EnableAfterFullSyncPoint(n"HorseTransitioning");
		else
			Manager.RightInteraction.EnableAfterFullSyncPoint(n"HorseTransitioning");

		HorseActor.HorseComponent.MovementState = EDerbyHorseMovementState::Still;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveTowardsTargetPoint(DeltaTime);
	}

	void MoveTowardsTargetPoint(float DeltaTime)
	{
		FHazeSplineSystemPosition SystemPosition;

		float EndPointDistance = HorseActor.SplineTrack.GetSplineDistanceAtGamePosition(EDerbyHorseState::Inactive);
		float CurrentDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(SplineFollowComp.Position.WorldLocation);

		float PredictedDistance = CurrentDistance - (MovementSpeed * DeltaTime);

		if(PredictedDistance > EndPointDistance)
		{
			//Perform full move
			if(SplineFollowComp.HasActiveSpline())
				SplineFollowComp.UpdateSplineMovement(-MovementSpeed * DeltaTime, SystemPosition);
			
			HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
		}
		else
		{
			//Move to Target
			if(SplineFollowComp.HasActiveSpline())
				SplineFollowComp.UpdateSplineMovement(HorseActor.SplineTrack.GetWorldLocationAtStatePosition(EDerbyHorseState::Inactive), SystemPosition);

			HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
			
			if(HasControl() && !bHaveReachedPos)
			{
				bHaveReachedPos = true;
				HorseActor.SwitchState(EDerbyHorseState::Inactive);
				Manager.ReachedPosition(HorseActor.InteractingPlayer, EDerbyHorseState::Inactive);
			}

			if (!bClearedSettings)
			{
				bClearedSettings = true;
			}
		}
	}
}