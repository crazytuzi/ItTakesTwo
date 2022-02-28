import Vino.Interactions.DoubleInteractionActor;
import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;

event void FPlayersReady();
event void FLiftSequence();

class ATimeBombDoubleInteract : ADoubleInteractionActor
{
	FPlayersReady EventPlayersReady;
	FLiftSequence EventLiftSequence;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshBaseComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshArrowComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ArrowDownAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ArrowUpAudioEvent;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayReady;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayWarmUp;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyWarmUp;
	//Cody_Bhv_TrackRunner_WarmUp

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyReady;
	//Cody_Bhv_TrackRunner_Ready

	// UPROPERTY(Category = "Audio")
	// UAkAudioEvent ArrowAudioEvent;

	float StartingPitch = 0.f;
	float GameOnPitch = -90.f;

	float PitchFloat;
	float CurrentSpeed;
	float MaxSpeed = 400.f;

	float EnableSpeed = 0.5f;

	bool bGameStarted;

	default bTurnOffTickWhenNotWaiting = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		MeshBaseComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshBaseComp) * CullDistanceMultiplier);
		MeshArrowComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshArrowComp) * CullDistanceMultiplier);
	}
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May, true);
		RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody, true);

		LeftInteraction.OnActivated.AddUFunction(this, n"StartAnimationMay");
		RightInteraction.OnActivated.AddUFunction(this, n"StartAnimationCody");

		OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"EndAnimationsForPlayerOnCancel");

		OnDoubleInteractionCompleted.AddUFunction(this, n"StartReadyAnimations");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentSpeed = FMath::FInterpTo(CurrentSpeed, MaxSpeed, DeltaTime, 1.2f);
		
		if (bGameStarted)
			PitchFloat = FMath::FInterpConstantTo(PitchFloat, GameOnPitch, DeltaTime, CurrentSpeed);
		else
			PitchFloat = FMath::FInterpConstantTo(PitchFloat, StartingPitch, DeltaTime, CurrentSpeed);

		FRotator NewRot = FRotator(PitchFloat, 0.f, 0.f);
		MeshArrowComp.SetRelativeRotation(NewRot);

		Super::Tick(DeltaTime);
	}

	void SetArrowGameStartedMode(bool InputBool)
	{
		if (InputBool)
			AudioArrowEventDown();
		else
			AudioArrowEventUp();
			
		bGameStarted = InputBool;
		CurrentSpeed = 0.f;
	}

	UFUNCTION()
	void StartAnimationMay(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.PlaySlotAnimation(Animation = MayWarmUp, bLoop = true);
		LeftInteraction.Disable(n"UsingTimeBomb");
	}

	UFUNCTION()
	void StartAnimationCody(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.PlaySlotAnimation(Animation = CodyWarmUp, bLoop = true);
		RightInteraction.Disable(n"UsingTimeBomb");
	}

	UFUNCTION()
	void StartReadyAnimations()
	{
		Game::May.PlaySlotAnimation(Animation = MayReady, bLoop = true, BlendTime = 0.8f);
		Game::Cody.PlaySlotAnimation(Animation = CodyReady, bLoop = true, BlendTime = 0.8f);
	}

	UFUNCTION(NetFunction)
	void EndAnimationsForPlayer(AHazePlayerCharacter Player)
	{
		Player.StopAllSlotAnimations(BlendTime = 0.7f);

		if (Player == Game::May)
			System::SetTimer(this, n"DelayedEnableMayInteraction", EnableSpeed, false);
		else
			System::SetTimer(this, n"DelayedEnableCodyInteraction", EnableSpeed, false);
	}

	UFUNCTION()
	void EndAnimationsForPlayerOnCancel(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		Player.StopAllSlotAnimations(BlendTime = 0.5f);

		if (Player == Game::May)
			System::SetTimer(this, n"DelayedEnableMayInteraction", EnableSpeed, false);
		else
			System::SetTimer(this, n"DelayedEnableCodyInteraction", EnableSpeed, false);
	}

	UFUNCTION()
	void DelayedEnableMayInteraction()
	{
		LeftInteraction.Enable(n"UsingTimeBomb");
	}
	
	UFUNCTION()
	void DelayedEnableCodyInteraction()
	{
		RightInteraction.Enable(n"UsingTimeBomb");
	}

	void EnableBothInteractions()
	{
		LeftInteraction.Enable(n"UsingTimeBomb");
		RightInteraction.Enable(n"UsingTimeBomb");
	}

	void AudioArrowEventDown()
	{
		AkComp.HazePostEvent(ArrowDownAudioEvent);
	}

	void AudioArrowEventUp()
	{
		AkComp.HazePostEvent(ArrowUpAudioEvent);
	}
}