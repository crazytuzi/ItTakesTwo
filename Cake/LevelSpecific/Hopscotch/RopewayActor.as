import Peanuts.Spline.SplineComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureCoatHanger;
import Vino.Tutorial.TutorialStatics;
import Vino.Triggers.VOBarkTriggerComponent;

event void FRopewaySignature();
event void FRopewayStarted();

class ARopewayActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USceneComponent AttachComponent;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionCompLeft;
	default InteractionCompLeft.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 2.f);
	default InteractionCompLeft.ActionShapeTransform.Location = FVector(0.f, 0.f, -190.f);
	default InteractionCompLeft.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = InteractionCompLeft)
	USkeletalMeshComponent PreviewMeshLeft;
	default PreviewMeshLeft.bIsEditorOnly = true;
	default PreviewMeshLeft.bHiddenInGame = true;
	default PreviewMeshLeft.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UInteractionComponent InteractionCompRight;
	default InteractionCompRight.ActionShapeTransform.Location = FVector(0.f, 0.f, -190.f);
	default InteractionCompRight.ActionShapeTransform.Scale3D = FVector (1.f, 1.f, 2.f);
	default InteractionCompRight.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = InteractionCompRight)
	USkeletalMeshComponent PreviewMeshRight;
	default PreviewMeshRight.bIsEditorOnly = true;
	default PreviewMeshRight.bHiddenInGame = true;
	default PreviewMeshRight.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UVOBarkTriggerComponent VOBarkTriggerComponent;
	default VOBarkTriggerComponent.Delay = 1.f;
	default VOBarkTriggerComponent.RetriggerDelays.Add(1.f);
	default VOBarkTriggerComponent.bRepeatForever = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeCameraComponent Cam;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RopewayStartedAudioEvent;

	UPROPERTY()
	FRopewaySignature RopewayFinishedEvent;

	UPROPERTY()
	FRopewayStarted RopewayStarted;

	UPROPERTY()
	ULocomotionFeatureCoatHanger CodyFeature;

	UPROPERTY()
	ULocomotionFeatureCoatHanger MayFeature;

	UPROPERTY()
	AActor MayJumpToLoc;

	UPROPERTY()
	AActor CodyJumpToLoc;

	FVector CamStartingLoc;

	TArray<AHazePlayerCharacter> PlayersUsingRopeway;

	bool bRopewayShouldMove = false;

	UPROPERTY()
	AActor CodyJumpToActor;
	
	UPROPERTY()
	AActor MayJumpToActor;

	UPROPERTY(Category = "VOBark")
	bool bVOBarkTriggerLocally = true;

	float RopewayDuration = 6.f;
	float RopewayDistance = 0.f;
	float RopewayAlpha = 0.f;
	float BlendSpaceSpeedTimerDuration = 3.5f;
	float BlendSpaceSpeedTimer = 0.f;
	float BlendSpaceSpeed = 0.f;
	private TPerPlayer<bool> BarkReady;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionCompLeft.OnActivated.AddUFunction(this, n"RopewayActivated");
		InteractionCompRight.OnActivated.AddUFunction(this, n"RopewayActivated");

		InteractionCompLeft.SetExclusiveForPlayer(EHazePlayer::May);
		InteractionCompRight.SetExclusiveForPlayer(EHazePlayer::Cody);

		DoubleInteract.OnTriggered.AddUFunction(this, n"BothPlayersOnRopeway");

		VOBarkTriggerComponent.bTriggerLocally = bVOBarkTriggerLocally;

		CamStartingLoc = Cam.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bRopewayShouldMove)
			return;

		if (BlendSpaceSpeedTimer <= BlendSpaceSpeedTimerDuration)
		{
			BlendSpaceSpeedTimer += DeltaTime;
			BlendSpaceSpeed = FMath::EaseIn(0.f, 100.f, BlendSpaceSpeedTimer / BlendSpaceSpeedTimerDuration, 2.f);
		}

		RopewayAlpha += DeltaTime / RopewayDuration;
		RopewayAlpha = FMath::Min(1.f, RopewayAlpha);
		RopewayDistance = FMath::EaseIn(0.f, Spline.GetSplineLength(), RopewayAlpha, 2.f);
		FVector NewLoc = Spline.GetLocationAtDistanceAlongSpline(RopewayDistance, ESplineCoordinateSpace::World);
		MeshRoot.SetWorldLocation(NewLoc);

		if (RopewayAlpha >= 0.8)
		{
			float CamLerp = FMath::GetMappedRangeValueClamped(FVector2D(0.8f, 1.f), FVector2D(0.f, 1.f), RopewayAlpha);
			float EaseLerp = FMath::EaseInOut(0.f, 1.f, CamLerp, 2.f);
			Cam.SetRelativeLocation(FMath::Lerp(CamStartingLoc, FVector(CamStartingLoc + FVector(1000.f, 0.f, 0.f)), EaseLerp));
		}

		if (RopewayAlpha >= 1.f)
		{
			bRopewayShouldMove = false;
			for (auto Player : Game::GetPlayers())
			{
				if (Player == Game::GetCody())
					Player.SetCapabilityAttributeObject(n"RopewayJumpToActor", CodyJumpToActor);
				else
					Player.SetCapabilityAttributeObject(n"RopewayJumpToActor", MayJumpToActor);
				
				Player.SetCapabilityAttributeNumber(n"RopewayFinished", 1);
				Player.SetCapabilityAttributeObject(n"RopewayInteractionComponent", nullptr);
			}
		}
	}

	UFUNCTION()
	void RopewayActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		if (PlayersUsingRopeway.AddUnique(Player))
		{
			VOBarkReady(Player);
			Player.AddCapability(n"RopewayCapability");
			Player.SetCapabilityAttributeObject(n"RopewayInteractionComponent", Comp);
			Player.SetCapabilityAttributeObject(n"RopewayActor", this);
			ShowCancelPrompt(Player, this);
			
			Comp.Disable(n"UsingRopeway");
			DoubleInteract.StartInteracting(Player);
		}		
	}

	UFUNCTION()
	void BothPlayersOnRopeway()
	{
		if (PlayersUsingRopeway.Num() == 2)
		{
			VOBarkCompleted();
			bRopewayShouldMove = true;
			RopewayStarted.Broadcast();
			Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
			FHazeCameraBlendSettings Blend;
			Game::GetMay().ActivateCamera(Cam, Blend, this);

			UHazeAkComponent::HazePostEventFireForget(RopewayStartedAudioEvent, this.GetActorTransform());

			for (auto  Player : Game::GetPlayers())
				RemoveCancelPromptByInstigator(Player, this);
		}
		else
		{
			ensure(false);
		}
	}

	UFUNCTION()
	void PlayerStoppedUsingRopeway(AHazePlayerCharacter Player)
	{
		VOBarkCancel(Player);
		DoubleInteract.CancelInteracting(Player);
		PlayersUsingRopeway.Remove(Player);
		RemoveCancelPromptByInstigator(Player, this);

		if (RopewayAlpha >= 1.f)
		{
			RopewayFinishedEvent.Broadcast();
			Game::GetMay().DeactivateCameraByInstigator(this);
		}

		FHazeJumpToData JumpData;
		JumpData.AdditionalHeight = 500.f;
		JumpData.Transform = Player == Game::GetMay() ? MayJumpToLoc.ActorTransform : CodyJumpToLoc.ActorTransform;
		JumpTo::ActivateJumpTo(Player, JumpData);
	}

	UFUNCTION()
	void SetInteractionPointEnabled(UInteractionComponent Comp)
	{
		Comp.Enable(n"UsingRopeway");
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkReady(AHazePlayerCharacter Player)
	{
		BarkReady[Player.Player] = true;
		VOBarkTriggerComponent.SetBarker(Player);

		// Bark is currently only used as a reminder for the other player
		// so should only trigger when exactly one player is interacting
		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnEnded(); // Two inteacting
		else
			VOBarkTriggerComponent.OnStarted(); // We're the only one
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCancel(AHazePlayerCharacter Player)
	{
		BarkReady[Player.Player] = false;
		VOBarkTriggerComponent.SetBarker(Player.OtherPlayer);

		// Bark is currently only used as a reminder for the other player
		// so should only trigger when exactly one player is interacting
		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnStarted(); // They're the only one
		else
			VOBarkTriggerComponent.OnEnded(); // Noone interacting
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCompleted()
	{
		// Bark can now safely expire.
		VOBarkTriggerComponent.bRepeatForever = false;
		VOBarkTriggerComponent.TriggerCount = VOBarkTriggerComponent.MaxTriggerCount;
		VOBarkTriggerComponent.OnEnded();
	}
}
