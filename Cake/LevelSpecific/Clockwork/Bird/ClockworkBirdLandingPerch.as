import Vino.ActivationPoint.ActivationPointStatics;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Vino.Interactions.DoubleInteractComponent;

event void FOnBothBirdsAtPerches(AClockworkBird CodyBird, AClockworkBird MayBird);

event void FOnBirdPerched(AClockworkBird Bird);
event void FOnBirdLaunchedFromPerch(AClockworkBird Bird);

class UClockworkBirdPerchActivationPoint : UHazeActivationPoint
{
	default InitializeDistance(EHazeActivationPointDistanceType::Visible, 30000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Targetable, 20000.f);
	default InitializeDistance(EHazeActivationPointDistanceType::Selectable, 7000.f);	
	default ValidationIdentifier = EHazeActivationPointIdentifierType::Movement;

	UFUNCTION(BlueprintOverride)
	EHazeActivationPointStatusType SetupActivationStatus(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& Query)const
	{	
		auto FlyingComp = UClockworkBirdFlyingComponent::Get(Player);
		if (FlyingComp == nullptr)
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (FlyingComp.MountedBird == nullptr)
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (!FlyingComp.MountedBird.bIsFlying)
			return EHazeActivationPointStatusType::InvalidAndHidden;
		if (FlyingComp.MountedBird.bIsLanding)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		auto LandingPerch = Cast<AClockworkBirdLandingPerch>(Owner);

		// Don't allow landing if a bird is already here
		if (LandingPerch.PerchedBird != nullptr)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't allow landing if a bird is already approaching the perch
		if (LandingPerch.ApproachingBird != nullptr)
			return EHazeActivationPointStatusType::InvalidAndHidden;

		// Don't allow landing from below or above the point
		if (FMath::Abs(WorldLocation.Z - FlyingComp.MountedBird.ActorLocation.Z) > 2500.f)
			return EHazeActivationPointStatusType::Invalid;

		// Only allow points that are not behind our current direction
		FVector DirectionToPoint = WorldLocation - FlyingComp.MountedBird.ActorLocation;
		DirectionToPoint.Z = 0.f;

		FVector BirdVelocity = FlyingComp.MountedBird.ActorVelocity;
		BirdVelocity.Z = 0.f;

		float DirectionDot = BirdVelocity.GetSafeNormal().DotProduct(DirectionToPoint.GetSafeNormal());
		if (DirectionDot < 0.f)
			return EHazeActivationPointStatusType::Invalid;

		return EHazeActivationPointStatusType::Valid;
	}

	UFUNCTION(BlueprintOverride)
	float SetupValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha) const
	{	
		const float ScoreAlpha = ActivationPointsStatics::CalculateValidationScoreAlpha(Player, Query, CompareDistanceAlpha);
		return ScoreAlpha;
	}	
};

class AClockworkBirdLandingPerch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UClockworkBirdPerchActivationPoint ActivationPoint;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "Clockwork Bird")
	AClockworkBird PerchedBird;
	AClockworkBird ApproachingBird;

	UPROPERTY()
	FOnBirdPerched OnBirdPerched;

	UPROPERTY()
	FOnBirdLaunchedFromPerch OnBirdLaunched;

	UPROPERTY()
	FOnBirdLaunchedFromPerch OnBirdLeftPerch;

	AClockworkBirdPerchDoubleInteract PerchDoubleInteract;

	void StartApproaching(AClockworkBird Bird)
	{
		if (HasControl())
			NetStartApproaching(Bird);
	}
	
	void StopApproaching(AClockworkBird Bird)
	{
		if (HasControl())
			NetStopApproaching(Bird);
	}

	void BirdPerched(AClockworkBird Bird)
	{
		ensure(Bird == ApproachingBird);
		ApproachingBird = nullptr;
		PerchedBird = Bird;
		OnBirdPerched.Broadcast(Bird);
	}

	void BirdLaunched(AClockworkBird Bird)
	{
		ensure(Bird == PerchedBird);
		PerchedBird = nullptr;
		OnBirdLaunched.Broadcast(Bird);
	}

	void BirdLeftPerch(AClockworkBird Bird)
	{
		ensure(Bird == PerchedBird);
		PerchedBird = nullptr;
		OnBirdLeftPerch.Broadcast(Bird);
	}

	bool CanLaunch(AClockworkBird Bird)
	{
		if (Bird != PerchedBird)
			return false;
		if (PerchDoubleInteract != nullptr)
			return PerchDoubleInteract.CanLaunch(Bird);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	private void NetStartApproaching(AClockworkBird Bird)
	{
		if (ApproachingBird == nullptr)
		{
			ApproachingBird = Bird;
		}
		else
		{
			// This is possible due to network, another player
			// could already be approaching before the message arrives.
			// This is handled by the LandOnPerch capability to cancel the
			// land if another player approaches.
		}
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	private void NetStopApproaching(AClockworkBird Bird)
	{
		if (ApproachingBird == Bird)
		{
			ApproachingBird = nullptr;
		}
	}
};

class AClockworkBirdPerchDoubleInteract : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;
	default Billboard.bIsEditorOnly = true;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY()
	FOnBothBirdsAtPerches BothBirdsAtPerches;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly)
	AClockworkBirdLandingPerch FirstPerch;

	UPROPERTY(BlueprintReadOnly, EditInstanceOnly)
	AClockworkBirdLandingPerch SecondPerch;

	private bool bWaitingForTrigger = false;

	void SetupPerch(AClockworkBirdLandingPerch Perch)
	{
		Perch.PerchDoubleInteract = this;

		Perch.OnBirdPerched.AddUFunction(this, n"BirdLanded");

		Perch.OnBirdLaunched.AddUFunction(this, n"BirdLeft");
		Perch.OnBirdLeftPerch.AddUFunction(this, n"BirdLeft");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (FirstPerch != nullptr)
			SetupPerch(FirstPerch);
		if (SecondPerch != nullptr)
			SetupPerch(SecondPerch);

		DoubleInteract.OnTriggered.AddUFunction(this, n"DoubleInteractTriggered");
	}

	bool CanLaunch(AClockworkBird Bird)
	{
		if (Bird.ActivePlayer == nullptr)
			return false;
		if (bWaitingForTrigger)
			return false;
		if (DoubleInteract.IsPlayerInteracting(Bird.ActivePlayer))
			return DoubleInteract.CanPlayerCancel(Bird.ActivePlayer);
		return true;
	}

	UFUNCTION()
	void DoubleInteractTriggered()
	{
		bWaitingForTrigger = true;
		UpdateWaitForTrigger();
	}

	void UpdateWaitForTrigger()
	{
		if (!bWaitingForTrigger)
			return;
		if (FirstPerch.PerchedBird == nullptr)
			return;
		if (SecondPerch.PerchedBird == nullptr)
			return;

		auto MayBird = FirstPerch.PerchedBird.ActivePlayer.IsMay() ? FirstPerch.PerchedBird : SecondPerch.PerchedBird;
		auto CodyBird = FirstPerch.PerchedBird.ActivePlayer.IsCody() ? FirstPerch.PerchedBird : SecondPerch.PerchedBird;
		BothBirdsAtPerches.Broadcast(CodyBird, MayBird);
		bWaitingForTrigger = false;
	}

	UFUNCTION()
	void BirdLanded(AClockworkBird Bird)
	{
		ensure(Bird.ActivePlayer != nullptr);
		DoubleInteract.StartInteracting(Bird.ActivePlayer);
		UpdateWaitForTrigger();
	}

	UFUNCTION()
	void BirdLeft(AClockworkBird Bird)
	{
		if (Bird.ActivePlayer != nullptr)
			DoubleInteract.CancelInteracting(Bird.ActivePlayer);
	}
};