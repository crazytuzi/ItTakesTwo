import Peanuts.Spline.SplineComponent;
import Vino.DoublePull.LocomotionFeatureDoublePull;

event void FOnEnterDoublePull(AHazePlayerCharacter Player);
event void FOnBothPlayersEnteredDoublePull();
event void FOnStartedEffort();
event void FOnExitDoublePull(AHazePlayerCharacter Player);
event void FOnCompleteDoublePull();

struct FDoublePullState
{
	AHazePlayerCharacter ActivePlayer;
	UHazeTriggerComponent ActiveTrigger;
	UHazeSmoothSyncVectorComponent SyncPullInput;
	bool bWantsToCancel = false;
	bool bCancelFinalized = false;
};

const float DOUBLE_PULL_MOVE_THRESHOLD = 0.2f;

class UDoublePullComponent : USceneComponent
{
	TPerPlayer<FDoublePullState> PullState;

	/* Sheet that the players should have while inside a double pull. */
	UPROPERTY()
	UHazeCapabilitySheet PullSheet = Asset("HazeCapabilitySheet'/Game/Blueprints/DoublePull/DoublePullSheet.DoublePullSheet'");

	/* Maximum angle away from the spline direction that the players can pull. */
	UPROPERTY()
	float MaximumLateralAngle = 30.f;

	/* Angle from backwards that is counted as dead, input is ignored. */
	UPROPERTY()
	float DeadLateralAngle = 30.f;

	/* Distance moved per pull effort. */
	UPROPERTY()
	float DistancePerPullEffort = 200.f;

	/* If we would end up within this distance from the end, just move to the actual end. */
	UPROPERTY()
	float PullEndDistanceMargin = 30.f;

	/* Effort curve that describes the non-linear strength of the players pulling. */
	UPROPERTY()
	UCurveFloat EffortCurve = Asset("CurveFloat'/Game/Blueprints/DoublePull/DoublePullEffortCurve.DoublePullEffortCurve'");

	/* Called whenever a player starts pulling. */
	UPROPERTY()
	FOnEnterDoublePull OnEnterDoublePull;

	/* Called whenever both players start pulling. */
	UPROPERTY()
	FOnBothPlayersEnteredDoublePull OnBothPlayersEnteredDoublePull;

	/* Called whenever double pull actor takes a step */
	UPROPERTY()
	FOnStartedEffort OnStartedEffort;

	/* Called whenever a player stops pulling. */
	UPROPERTY()
	FOnExitDoublePull OnExitDoublePull;

	/* Called when the double pull reaches the end. */
	UPROPERTY()
	FOnCompleteDoublePull OnCompleteDoublePull;

	/* Locomotion feature for cody using this double pull. */
	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature = Asset("LocomotionFeatureDoublePull'/Game/Blueprints/DoublePull/DA_DoublePullFeature_Default_Cody.DA_DoublePullFeature_Default_Cody'");

	/* Locomotion feature for may using this double pull. */
	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature = Asset("LocomotionFeatureDoublePull'/Game/Blueprints/DoublePull/DA_DoublePullFeature_Default_May.DA_DoublePullFeature_Default_May'");

	/* Rotation offset applied to the rotation on spline for the actor. */
	UPROPERTY()
	FRotator RotationOffset;

	/* Current spline used for the double pull. */
	UPROPERTY() 
	UHazeSplineComponent Spline;

	/* Whether we've already reached the end of the spline. */
	bool bCompleted = false;

	bool bIsExertingPullEffort = false;
	float EffortDuration = 0.f;
	float CurrentEffort = 0.f;

	/* Internal state for players managed by the double pull. */
	TArray<UHazeTriggerComponent> Triggers;

	/* Networking state */
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (auto Player : Game::GetPlayers())
		{
			auto& State = PullState[Player];
			State.SyncPullInput = UHazeSmoothSyncVectorComponent::GetOrCreate(
				Owner, 
				Player.IsCody() ? n"DoublePull_Cody" : n"DoublePull_May");
			State.SyncPullInput.OverrideControlSide(Player);
		}

		CrumbComp = UHazeCrumbComponent::GetOrCreate(Owner);

		// Figure out how long a pull effort is
		if (EffortCurve != nullptr)
		{
			float MinTime = 0.f;
			float MaxTime = 0.f;
			EffortCurve.GetTimeRange(MinTime, MaxTime);

			EffortDuration = FMath::Max(MaxTime, 0.01f);
		}
		else
		{
			EffortDuration = 1.f;
		}
	}

	/* === Interaction helpers === */
	UFUNCTION()
	void RemoveTrigger(UHazeTriggerComponent Trigger)
	{
		Triggers.Remove(Trigger);

		for (auto& State : PullState)
		{
			if (State.ActiveTrigger == Trigger)
			{
				RemovePlayerFromTrigger(State.ActiveTrigger, State.ActivePlayer);
			}
		}
	}

	UFUNCTION()
	void AddTrigger(UHazeTriggerComponent Trigger)
	{
		Triggers.Add(Trigger);
		Trigger.AddActivationDelegate(FHazeTriggerActivationDelegate(this, n"OnTriggerUsed"));
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTriggerUsed(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		LockPlayerIntoTrigger(Trigger, Player);
	}

	UFUNCTION()
	void EnterDoublePull(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		auto& State = PullState[Player];

		devEnsure(State.ActiveTrigger == nullptr, "Entered double pull while already in double pull.");
		if (State.ActiveTrigger != nullptr)
			return;

		LockPlayerIntoTrigger(Trigger, Player);

		// Fire event if both players are interacting
		if(PullState[Player.OtherPlayer].ActivePlayer != nullptr)
			OnBothPlayersEnteredDoublePull.Broadcast();
	}

	UFUNCTION()
	void ExitDoublePull(AHazePlayerCharacter Player)
	{
		auto& State = PullState[Player];
		devEnsure(State.ActiveTrigger != nullptr, "Canceled double pull for player not in double pull.");

		if (State.ActiveTrigger == nullptr)
			return;

		RemovePlayerFromTrigger(State.ActiveTrigger, Player);
	}

	private void LockPlayerIntoTrigger(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		auto& State = PullState[Player];
		State.ActiveTrigger = Trigger;
		State.ActivePlayer = Player;
		State.bWantsToCancel = false;
		State.bCancelFinalized = false;

		Trigger.Disable(n"InUse");
		Player.TriggerMovementTransition(this);
		Player.AddCapabilitySheet(PullSheet, EHazeCapabilitySheetPriority::Interaction, Instigator = this);
		Player.SetCapabilityAttributeObject(n"DoublePull", this);

		Player.AddLocomotionFeature(GetPlayerFeature(Player));

		OnEnterDoublePull.Broadcast(Player);
	}

	private void RemovePlayerFromTrigger(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		auto& State = PullState[Player];
		State.ActiveTrigger = nullptr;
		State.ActivePlayer = nullptr;
		State.bWantsToCancel = false;
		State.bCancelFinalized = false;
		if (State.SyncPullInput.HasControl())
			State.SyncPullInput.Value = FVector(0.f);

		Player.SetCapabilityAttributeObject(n"DoublePull", nullptr);
		Player.RemoveCapabilitySheet(PullSheet, Instigator = this);
		Player.RemoveLocomotionFeature(GetPlayerFeature(Player));

		OnExitDoublePull.Broadcast(Player);
		Trigger.EnableAfterFullSyncPoint(n"InUse");
	}

	void CancelFromPlayer(AHazePlayerCharacter Player)
	{
		NetRequestCancel(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Process cancel requests when we're not exerting pull effort
		if (!bIsExertingPullEffort)
		{
			for (auto Player : Game::GetPlayers())
			{
				auto& State = PullState[Player];
				if (State.ActivePlayer == nullptr)
					continue;
				if (State.bWantsToCancel && HasControl())
					NetFinalizeCancel(Player);
				if (State.bCancelFinalized)
					PerformCancel(Player);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetRequestCancel(AHazePlayerCharacter Player)
	{
		PullState[Player].bWantsToCancel = true;
	}

	UFUNCTION(NetFunction)
	private void NetFinalizeCancel(AHazePlayerCharacter Player)
	{
		PullState[Player].bCancelFinalized = true;
	}

	void PerformCancel(AHazePlayerCharacter Player)
	{
		ULocomotionFeatureDoublePull Feature = ULocomotionFeatureDoublePull::Get(Player);
		ExitDoublePull(Player);
		Player.PlayEventAnimation(Animation = Feature.CancelAnimation);
	}

	UHazeTriggerComponent GetTriggerUsedByPlayer(AHazePlayerCharacter Player)
	{
		auto& State = PullState[Player];
		return State.ActiveTrigger;
	}

	bool IsAnyPlayerInteracting()
	{
		return PullState[0].ActivePlayer != nullptr || PullState[1].ActivePlayer != nullptr;
	}

	bool AreBothPlayersInteracting()
	{
		return PullState[0].ActivePlayer != nullptr && PullState[1].ActivePlayer != nullptr;
	}

	bool IsPlayerInteracting(AHazePlayerCharacter Player)
	{
		return PullState[Player].ActiveTrigger != nullptr;
	}

	/* === Spline Helpers === */
	void CompletedDoublePull()
	{
		bCompleted = true;
		OnCompleteDoublePull.Broadcast();
	}

	void ResetDoublePull()
	{
		bCompleted = false;
	}

	void SwitchToSpline(UHazeSplineComponent NewSpline, bool bTeleportToStart)
	{
		Spline = NewSpline;
		bCompleted = false;

		if (bTeleportToStart)
			Owner.ActorLocation = NewSpline.GetLocationAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
	}

	/* === Input Helpers === */
	void SetPlayerInputDirection(AHazePlayerCharacter Player, FVector Input)
	{
		ensure(Player.HasControl());

		auto& State = PullState[Player];
		State.SyncPullInput.Value = Input;
	}

	bool IsValidPullDirection(FVector Input)
	{
		if (Input.Size() < 0.5f)
			return false;
		
		FVector SplineDirection = Spline.FindDirectionClosestToWorldLocation(Owner.ActorLocation, ESplineCoordinateSpace::World);

		float AngleToBackwards = (-SplineDirection).AngularDistance(Input);
		if (AngleToBackwards < FMath::DegreesToRadians(DeadLateralAngle))
			return false;

		return true;
	}

	FVector GetConstrainedPullDirection(FVector Input)
	{
		// Get data from the spline at current position
		FVector CurrentSplineLocation;
		float CurrentSplinePos = 0.f;

		Spline.FindDistanceAlongSplineAtWorldLocation(Owner.ActorLocation, CurrentSplineLocation, CurrentSplinePos);

		FRotator RotationOnSpline = Spline.GetRotationAtDistanceAlongSpline(CurrentSplinePos, ESplineCoordinateSpace::World);
		FVector CurrentSplineDirection = RotationOnSpline.ForwardVector;
		FVector InputOnSplinePlane = Input.VectorPlaneProject(RotationOnSpline.UpVector).GetSafeNormal();

		float AngleToForward = FMath::RadiansToDegrees(CurrentSplineDirection.AngularDistance(InputOnSplinePlane));
		if (AngleToForward > 0.f)
		{
			float AnglePct = AngleToForward / MaximumLateralAngle;
			if (AnglePct > 1.f)
			{
				FRotator InputDir = FRotator::MakeFromX(InputOnSplinePlane);
				FRotator SplineDir = FRotator::MakeFromX(CurrentSplineDirection);

				FRotator ResultDir = FMath::LerpShortestPath(SplineDir, InputDir, 1.f / AnglePct);
				return ResultDir.ForwardVector;
			}
		}

		return InputOnSplinePlane;
	}

	FVector ConstrainPointToSpline(FVector Point)
	{
		FVector ClosestSplineLocation;
		float SplinePos = 0.f;
		Spline.FindDistanceAlongSplineAtWorldLocation(Point, ClosestSplineLocation, SplinePos);

		FRotator RotationOnSpline = Spline.GetRotationAtDistanceAlongSpline(SplinePos, ESplineCoordinateSpace::World);
		FVector PointOnSplinePlane = Point.PointPlaneProject(ClosestSplineLocation, RotationOnSpline.UpVector);

		FVector SplineScale = Spline.GetScaleAtDistanceAlongSpline(SplinePos);
		float MaxSplineLateralDist = SplineScale.Y * 100.f;

		FVector SplineToPoint = (PointOnSplinePlane - ClosestSplineLocation);
		float DistOnLateral = RotationOnSpline.RightVector.DotProduct(SplineToPoint);

		if (FMath::Abs(DistOnLateral) >= MaxSplineLateralDist)
		{
			// Redirect target to stay within the spline tube
			DistOnLateral = MaxSplineLateralDist * FMath::Sign(DistOnLateral);
			return ClosestSplineLocation + (RotationOnSpline.RightVector * DistOnLateral);
		}
		else
		{
			return PointOnSplinePlane;
		}
	}

	/* === Animation Helpers === */
	UHazeLocomotionFeatureBase GetPlayerFeature(AHazePlayerCharacter Player)
	{
		return Player.IsCody() ? CodyFeature : MayFeature;
	}

	void SetAnimationParams(AHazeActor Actor, FVector Direction)
	{
		Actor.SetAnimBoolParam(n"DoublePullIsMoving", bIsExertingPullEffort);
		Actor.SetAnimFloatParam(n"DoublePullEffort", CurrentEffort);

		FVector SplineDirection = Spline.FindDirectionClosestToWorldLocation(Owner.ActorLocation, ESplineCoordinateSpace::World);
		float InputOnSpline = Direction.DotProduct(SplineDirection);
		float InputAwayFromSpline = Direction.DotProduct(SplineDirection.CrossProduct(FVector::UpVector));

		Actor.SetAnimFloatParam(n"DoublePullInputMagnitude", Direction.Size());
		Actor.SetAnimFloatParam(n"DoublePullBackwardsPull", InputOnSpline);
		Actor.SetAnimFloatParam(n"DoublePullHorizontalPull", InputAwayFromSpline);
	}

	FVector GetRemoteAnimationInput(AHazePlayerCharacter Player)
	{
		return PullState[Player].SyncPullInput.Value;
	}
};