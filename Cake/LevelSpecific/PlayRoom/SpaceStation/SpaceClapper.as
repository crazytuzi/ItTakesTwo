import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.PlayerHealth.PlayerRespawnComponent;

UCLASS(Abstract)
class ASpaceClapper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TopRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BottomRoot;

	UPROPERTY(DefaultComponent, Attach = TopRoot)
	UBoxComponent TopBox;

	UPROPERTY(DefaultComponent, Attach = TopRoot)
	UBoxComponent BottomBox;

	UPROPERTY(DefaultComponent, Attach = TopBox)
	UNiagaraComponent TopEffect;
	default TopEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = BottomBox)
	UNiagaraComponent BottomEffect;
	default BottomEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.bTickWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY()
	float StartDelay = 0.f;

	UPROPERTY()
	float MoveDuration = 0.35f;

	UPROPERTY()
	float MoveInterval = 6.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoveClapperAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FinishMoveClapperAudioEvent;

	float StartGameTime = 0.f;

	bool bIsMoving = false;
	bool bMoveForward = true;
	bool bWantToDisable = false;

	TArray<AHazePlayerCharacter> AttachedPlayers;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartGameTime = Time::GetGameTimeSeconds();
		bMoveForward = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ActiveTime = Time::GetGameTimeSince(StartGameTime) - StartDelay;
		if (ActiveTime >= 0.f)
		{
			float LoopDuration = MoveDuration + MoveInterval;
			float Position = (ActiveTime % LoopDuration);
			int bParity = (FMath::FloorToInt(ActiveTime / LoopDuration) % 2);

			bool bShouldBeMoving = (Position < MoveDuration);
			bool bShouldBeForward = (bParity == 0);

			if (bShouldBeMoving && !bIsMoving)
			{
				StartMovingClapper();
				bIsMoving = true;
				bMoveForward = bShouldBeForward;
			}

			if (bShouldBeMoving)
			{
				float MovePosition = FMath::Clamp(Position / MoveDuration, 0.f, 1.f);
				if (!bMoveForward)
					MovePosition = 1.f - MovePosition;
				UpdateMoveClapper(MovePosition);
			}

			if (!bShouldBeMoving && bIsMoving)
			{
				UpdateMoveClapper(bMoveForward ? 1.f : 0.f);
				FinishMoveClapper();
				bIsMoving = false;
			}
		}

		if (bWantToDisable && !bIsMoving)
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		bWantToDisable = true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		bWantToDisable = false;
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ClearCameraSettingsByInstigator(this, 0.f);
	}

	UFUNCTION()
	void StartMovingClapper()
	{
		UHazeAkComponent::HazePostEventFireForget(MoveClapperAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveClapper(float CurValue)
	{
		float Rot = FMath::Lerp(0.f, 180.f, CurValue);
		TopRoot.SetRelativeRotation(FRotator(0.f, 0.f, -Rot));
		BottomRoot.SetRelativeRotation(FRotator(0.f, 0.f, Rot));

		UBoxComponent BoxToCheck = bMoveForward ? TopBox : BottomBox;

		TArray<AActor> Actors;
		BoxToCheck.GetOverlappingActors(Actors, AHazePlayerCharacter::StaticClass());

		for (AActor CurActor : Actors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CurActor);
			if (Player != nullptr && !AttachedPlayers.Contains(Player))
			{
				if (Player.HasControl())
					NetEnterClapper(Player, Player.ActorTransform.GetRelativeTransform(TopRoot.WorldTransform));
				AttachedPlayers.Add(Player);
			}
		}
	}

	UFUNCTION(NetFunction)
	private void NetEnterClapper(AHazePlayerCharacter Player, FTransform KilledTransform)
	{
		Player.TriggerMovementTransition(this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.AttachToComponent(TopRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		Player.SetActorTransform(KilledTransform * TopRoot.WorldTransform);

		FHazeCameraSpringArmSettings CamSettings;
		CamSettings.MinDistance = 1000.f;
		CamSettings.bUseMinDistance = true;
		Player.ApplyCameraSpringArmSettings(CamSettings, FHazeCameraBlendSettings(1.f), this);

		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnRespawn.AddUFunction(this, n"PlayerRespawned");
	}

	UFUNCTION(NetFunction)
	private void NetKilledByClapper(AHazePlayerCharacter Player)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.TriggerMovementTransition(this);

		KillPlayer(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveClapper()
	{
		if (bMoveForward)
			TopEffect.Activate(true);
		else
			BottomEffect.Activate(true);

		bMoveForward = !bMoveForward;

		for (AHazePlayerCharacter CurPlayer : AttachedPlayers)
		{
			if (CurPlayer.HasControl())
				NetKilledByClapper(CurPlayer);
		}

		ForceFeedbackComp.Play();

		AttachedPlayers.Empty();

		UHazeAkComponent::HazePostEventFireForget(FinishMoveClapperAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerRespawned(AHazePlayerCharacter Player)
	{
		Player.ClearCameraSettingsByInstigator(this, 0.f);
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnRespawn.Unbind(this, n"PlayerRespawned");
	}
}