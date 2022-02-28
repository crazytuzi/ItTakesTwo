import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
event void FClockworkRetractingLeverSignature(float PullAlpha);
event void FClockworkRetractingLeverSignatureNoValue();
event void FClockworkRetractingLeverInstigatorEvent(AHazePlayerCharacter Player);

class AClockworkRetractingLever : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = BaseMesh)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PullLeverAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PullLeverAndRetractAudioEvent;

	UPROPERTY()
	FClockworkRetractingLeverSignature PullLeverEvent;

	UPROPERTY()
	FClockworkRetractingLeverInstigatorEvent PullLeverInstigatorEvent;

	UPROPERTY()
	FClockworkRetractingLeverSignatureNoValue LeverWasPulledEvent;

	UPROPERTY()
	UAnimSequence CodyPullAnim;

	UPROPERTY()
	UAnimSequence MayPullAnim;

	UPROPERTY()
	FHazeTimeLike PullLeverTimeline;
	default PullLeverTimeline.Duration = 0.2f;

	UPROPERTY()
	bool bShouldRetract;
	default bShouldRetract = true;
	
	float PullAmount;
	float PullAmountMax;
	float ActualPullAmount;

	FRotator LeverStartingRotation = FRotator(45.f, 0.f, 0.f);
	FRotator LeverTargetRotation = FRotator(-45.f, 0.f, 0.f);

	FHazeAnimationDelegate BlendOut;

	bool bLeverHasBeenPulled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		PullLeverTimeline.BindUpdate(this, n"PullLeverTimelineUpdate");
		BlendOut.BindUFunction(this, n"BlendingOut");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bLeverHasBeenPulled)
			return;

		if (!PullLeverTimeline.IsPlaying() && bShouldRetract)
		{
			PullAmount -= DeltaTime * 0.3f;
			ActualPullAmount = FMath::ExpoOut(0.f, 1.f, PullAmount);

			if (ActualPullAmount <= 0.f)
			{
				PullAmount = 0.f;
				ActualPullAmount = 0.f;
				bLeverHasBeenPulled = false;
				InteractionComp.Enable(n"LeverPulled");
			}
		}
		LeverMesh.SetRelativeRotation(QuatLerp(LeverStartingRotation, LeverTargetRotation, ActualPullAmount));
		PullLeverEvent.Broadcast(ActualPullAmount);

		if (ActualPullAmount >= 1.f && !bShouldRetract)
		{
			bLeverHasBeenPulled = false;
			LeverWasPulledEvent.Broadcast();
		}
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"LeverPulled");
		UAnimSequence AnimToPlay = Player == Game::GetCody() ? CodyPullAnim : MayPullAnim;
		Player.PlayEventAnimation(BlendOut, FHazeAnimationDelegate(), AnimToPlay);
		PullLeverInstigatorEvent.Broadcast(Player);

		if(bShouldRetract)
		{
			Player.PlayerHazeAkComp.HazePostEvent(PullLeverAndRetractAudioEvent);
		}

		if(!bShouldRetract)
		{
			Player.PlayerHazeAkComp.HazePostEvent(PullLeverAudioEvent);
		}
	}

	UFUNCTION()
	void BlendingOut()
	{
		PullLeverTimeline.PlayFromStart();
		bLeverHasBeenPulled = true;
	}

	UFUNCTION()
	void PullLeverTimelineUpdate(float CurrentValue)
	{
		PullAmount = CurrentValue;
		ActualPullAmount = CurrentValue;
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