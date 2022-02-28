import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;
import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class ASwingingHopscotchBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SwingRoot;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	UStaticMeshComponent BallMesh;
	default BallMesh.bGenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	UStaticMeshComponent CableMesh;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	UStaticMeshComponent CircleMesh01;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	UStaticMeshComponent CircleMesh02;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent Impacts;

	UPROPERTY()
	float SpeelMultiplier = 1.f;

	UPROPERTY()
	float SwingAmount;
	default SwingAmount = 40.f;

	UPROPERTY()
	FHazeTimeLike SwingBallTimeline;
	default SwingBallTimeline.Duration = 3.f;
	default SwingBallTimeline.bLoop = true;
	default SwingBallTimeline.bFlipFlop = true;
	default SwingBallTimeline.bSyncOverNetwork = true;
	default SwingBallTimeline.SyncTag = n"SwingingHopscotchBall";

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	TPerPlayer<bool> bHasLaunched;
	float LaunchLimitDelayCody = 0.f;
	float LaunchLimitDelayMay = 0.f;

	FRotator StartingRot;
	FRotator TargetRot;

	UPROPERTY()
	float StartDelay;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSwingingAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BounceEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingBallTimeline.BindUpdate(this, n"SwingBallTimelineUpdate");
		SwingBallTimeline.SetPlayRate(SpeelMultiplier);
	
		Impacts.OnActorForwardImpactedByPlayer.AddUFunction(this, n"ForwardPlayerLandedOnBanana");

		System::SetTimer(this, n"StartTimeline", StartDelay, false);

		HazeAkComp.SetRTPCValue("Rtpc_Hopscotch_Amb_Spot_InflatableBanana_SpeedMultiplier", SpeelMultiplier);
		HazeAkComp.HazePostEvent(StartSwingingAudioEvent);

		StartingRot = FRotator(0.f, 0.f, -SwingAmount);
		TargetRot = FRotator(0.f, 0.f, SwingAmount);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bHasLaunched[Game::GetCody()])
		{
			LaunchLimitDelayCody -= DeltaTime;
			if (LaunchLimitDelayCody <= 0.f)
			{
				Game::GetCody().MovementComponent.StopIgnoringActor(this);
				bHasLaunched[Game::GetCody()] = false;
			}
		}

		if (bHasLaunched[Game::GetMay()])
		{
			LaunchLimitDelayMay -= DeltaTime;
			if (LaunchLimitDelayMay <= 0.f)
			{
				Game::GetMay().MovementComponent.StopIgnoringActor(this);
				bHasLaunched[Game::GetMay()] = false;
			}
		}
	}
	
	UFUNCTION()
	void ForwardPlayerLandedOnBanana(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		if (bHasLaunched[Player])
			return;

		if (Player == Game::GetCody())
			LaunchLimitDelayCody = .25f;
		else
			LaunchLimitDelayMay = .25f;

		bHasLaunched[Player] = true;
		Player.MovementComponent.StartIgnoringActor(this);
		Player.SetCapabilityActionState(n"BananaBounce", EHazeActionState::Active);
		Player.PlayerHazeAkComp.HazePostEvent(BounceEvent);
	}

	UFUNCTION()
	void StartTimeline()
	{
		SwingBallTimeline.PlayFromStart();
	}

	UFUNCTION()
	void SwingBallTimelineUpdate(float CurrentValue)
	{
		SwingRoot.SetRelativeRotation(QuatLerp(StartingRot, TargetRot, CurrentValue));
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}