import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;

class UDerbyHorseStartCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorse");
	default CapabilityTags.Add(n"DerbyHorseMovement");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ADerbyHorseActor HorseActor;
	AHorseDerbyManager Manager;
	UHazeSplineComponent SplineComp;
	UHazeSplineFollowComponent SplineFollowComp;
	AHazePlayerCharacter Player;

	float MovementSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		Manager = Cast<AHorseDerbyManager>(GetAttributeObject(n"Manager"));
		SplineFollowComp = HorseActor.SplineFollowComp;
		SplineComp = HorseActor.SplineTrack.SplineComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HorseActor.InteractingPlayer != nullptr && HorseActor.HorseState != EDerbyHorseState::AwaitingStart && Manager.Gamestate == EDerbyHorseState::AwaitingStart)
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HorseActor.InteractingPlayer == nullptr || Manager.Gamestate != EDerbyHorseState::AwaitingStart || HorseActor.HorseState == EDerbyHorseState::AwaitingStart)
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
		Player = HorseActor.InteractingPlayer;
		HorseActor.HorseState = EDerbyHorseState::Travelling;

		HorseActor.HorseComponent.MovementState = EDerbyHorseMovementState::Trot;

		if(!SplineFollowComp.HasActiveSpline())
			SplineFollowComp.ActivateSplineMovement(SplineComp, true);

		MovementSpeed = Manager.GameInactiveHorseSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
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

		int DirSign;

		float EndPointDistance = HorseActor.SplineTrack.GetSplineDistanceAtGamePosition(EDerbyHorseState::AwaitingStart);
		float CurrentDistance = 0.f;

		if (SplineFollowComp.HasActiveSpline())
			CurrentDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(SplineFollowComp.Position.WorldLocation);

		float DeltaDistance = EndPointDistance - CurrentDistance;

		DirSign = FMath::Sign(DeltaDistance);

		float PredictedDistance = CurrentDistance + ((MovementSpeed * DirSign) * DeltaTime);

		if(DirSign > 0)
		{
			if(PredictedDistance < EndPointDistance)
			{
				//Perform full move
				if(SplineFollowComp.HasActiveSpline())
					SplineFollowComp.UpdateSplineMovement((MovementSpeed * DirSign) * DeltaTime, SystemPosition);
			}
			else
			{
				//Move to Target
				if(SplineFollowComp.HasActiveSpline())
					SplineFollowComp.UpdateSplineMovement(HorseActor.SplineTrack.GetWorldLocationAtStatePosition(EDerbyHorseState::AwaitingStart), SystemPosition);

				if(HasControl())
				{
					HorseActor.SwitchState(EDerbyHorseState::AwaitingStart);
					Manager.ReachedPosition(Player, HorseActor.HorseState);
				}
			}
		}
		else
		{
			if(PredictedDistance > EndPointDistance)
			{
				//Perform full move
				if(SplineFollowComp.HasActiveSpline())
					SplineFollowComp.UpdateSplineMovement((MovementSpeed * DirSign) * DeltaTime, SystemPosition);
			}
			else
			{
				//Move to Target
				if(SplineFollowComp.HasActiveSpline())
					SplineFollowComp.UpdateSplineMovement(HorseActor.SplineTrack.GetWorldLocationAtStatePosition(EDerbyHorseState::AwaitingStart), SystemPosition);

				if(HasControl())
				{
					HorseActor.SwitchState(EDerbyHorseState::AwaitingStart);
					Manager.ReachedPosition(Player, HorseActor.HorseState);
				}
			}
		}

		if (SplineFollowComp.HasActiveSpline())
			HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
	}
}