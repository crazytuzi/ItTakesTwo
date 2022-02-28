
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.Swarm.Encounters.Slide.SwarmSlideRubberbandVolume;

class USwarmSlidePursueSplineCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::PursueSpline;

	USwarmSlideComposeableRubberbandSettings RBSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if (!SwarmActor.MovementComp.HasSplineToFollow())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!SwarmActor.MovementComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Slide.PursueSpline.AnimSettingsDataAsset,
			this
		);

		RBSettings = USwarmSlideComposeableRubberbandSettings::GetSettings(SwarmActor);

		BehaviourComp.NotifyStateChanged();

		MoveComp.InitMoveAlongSpline();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		RBSettings = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		UHazeSplineComponentBase RubberbandSpline = nullptr;
		if(MoveComp.RubberbandSplineActor != nullptr)
			RubberbandSpline = UHazeSplineComponent::Get(MoveComp.RubberbandSplineActor);
		else
			RubberbandSpline = MoveComp.SplineSystemPos.GetSpline();

		AHazePlayerCharacter May, Cody;
		Game::GetMayCody(May, Cody);

		float SplineDistance_May = 0.f;
		FVector SplinePos_May = FVector::ZeroVector;
		RubberbandSpline.FindDistanceAlongSplineAtWorldLocation(May.GetActorLocation(), SplinePos_May, SplineDistance_May);

		float SplineDistance_Cody = 0.f;
		FVector SplinePos_Cody = FVector::ZeroVector;
		RubberbandSpline.FindDistanceAlongSplineAtWorldLocation(Cody.GetActorLocation(), SplinePos_Cody, SplineDistance_Cody);

		// figure out who is in front
		float SplineDistance_Front = 0.f;
		AHazePlayerCharacter FrontPlayer = nullptr;
		FVector SplinePos_Front = FVector::ZeroVector;
		if (SplineDistance_May > SplineDistance_Cody)
		{
			SplinePos_Front = SplinePos_May;
			SplineDistance_Front = SplineDistance_May;
			FrontPlayer = May;
		}
		else
		{
			SplinePos_Front = SplinePos_Cody;
			SplineDistance_Front = SplineDistance_Cody;
			FrontPlayer = Cody;
		}

		// Get the speed of the furthermost player on the spline, in the splines direction
		UHazeMovementComponent MoveComp_Front = UHazeMovementComponent::GetOrCreate(FrontPlayer);
		const FVector SplineDir = RubberbandSpline.GetDirectionAtDistanceAlongSpline( SplineDistance_Front, ESplineCoordinateSpace::World);
		float SplineSpeed_Front = MoveComp_Front.GetVelocity().ProjectOnToNormal(SplineDir).Size();

		// figure out desired distance along spline
		const float DesiredDistanceAlongSpline = SplineDistance_Front + RBSettings.IdealDistance;

		// get distance along spline for the swarm.
		float SplineDistance_Swarm = 0.f;
		FVector SplinePos_Swarm = FVector::ZeroVector;
		RubberbandSpline.FindDistanceAlongSplineAtWorldLocation(SwarmActor.GetActorLocation(), SplinePos_Swarm, SplineDistance_Swarm);

		float InterSpeed = SplineSpeed_Front;

		// Ahead relation
		if (SplineDistance_Swarm > DesiredDistanceAlongSpline)
		{
			const float AheadAlpha = Math::GetPercentageBetweenClamped(
				DesiredDistanceAlongSpline,
				DesiredDistanceAlongSpline + RBSettings.AheadDistance,
				SplineDistance_Swarm
			);

			InterSpeed = FMath::Lerp(
				SplineSpeed_Front,
				SplineSpeed_Front * RBSettings.AheadSpeedMultiplier,
				AheadAlpha
			);
		}
		// Behind relation
		else
		{
			const float BehindAlpha = Math::GetPercentageBetweenClamped(
				DesiredDistanceAlongSpline - RBSettings.BehindDistance,
				DesiredDistanceAlongSpline,
				SplineDistance_Swarm
			);

			InterSpeed = FMath::Lerp(
				SplineSpeed_Front * RBSettings.BehindSpeedMultiplier,
				SplineSpeed_Front,
				BehindAlpha	
			);
		}

		// DEBUG
		// FVector IdealPos = RubberbandSpline.GetLocationAtDistanceAlongSpline(DesiredDistanceAlongSpline, ESplineCoordinateSpace::World);
		// FVector AheadPos = RubberbandSpline.GetLocationAtDistanceAlongSpline(DesiredDistanceAlongSpline + RBSettings.AheadDistance, ESplineCoordinateSpace::World);
		// FVector BehindPos = RubberbandSpline.GetLocationAtDistanceAlongSpline(DesiredDistanceAlongSpline - RBSettings.BehindDistance, ESplineCoordinateSpace::World);
		// FVector SwarmPosOnSpline = RubberbandSpline.GetLocationAtDistanceAlongSpline( SplineDistance_Swarm, ESplineCoordinateSpace::World);
		// System::DrawDebugPoint(SwarmActor.GetActorLocation(), 40.f, FLinearColor::Yellow, 0.f);
		// System::DrawDebugPoint(IdealPos, 10.f, FLinearColor::Blue, 0.f);
		// System::DrawDebugPoint(BehindPos, 10.f, FLinearColor::Red, 0.f);
		// System::DrawDebugPoint(AheadPos, 10.f, FLinearColor::Green, 0.f);
		// PrintToScreen("Player Speed on spline: " + SplineSpeed_Front);
		// PrintToScreen("Swarm Rubber speed: " + InterSpeed);
		// PrintToScreen("Spline Distance SWARM: " + SplineDistance_Swarm);
		// PrintToScreen("Spline Distance FRONT: " + SplineDistance_Front);
		// PrintToScreen("Spline Distance Delta : " + FMath::Max(0.f, SplineDistance_Swarm - SplineDistance_Front));

		// Pursue along spline 
		if(InterSpeed != 0.f)
			MoveComp.MoveAlongSpline(InterSpeed, DeltaSeconds);

		// We'll do this until LVL BP switches behaviour. 
		BehaviourComp.FinalizeBehaviour();
	}

}



