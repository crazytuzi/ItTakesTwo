import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundStatics;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

UCLASS(Abstract)
class ASpaceGroundPoundFlipBoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USceneComponent BoardRoot;

	UPROPERTY(DefaultComponent, Attach = BoardRoot)
	UStaticMeshComponent BoardMesh;

	UPROPERTY(DefaultComponent, Attach = BoardRoot)
	UStaticMeshComponent TopPlatform;

	UPROPERTY(DefaultComponent, Attach = BoardRoot)
	UStaticMeshComponent BottomPlatform;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FlipTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike WiggleTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect FlipForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> FlipCameraShake;

	TPerPlayer<float> LastGroundPoundGameTime;
	TPerPlayer<bool> bLockedIntoGroundPound;

	bool bFlipped = false;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundpoundedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WiggleFinishAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FlipFinishAudioEvent;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -5.f;
	default PhysValue.UpperBound = 5.f;
	default PhysValue.LowerBounciness = 0.2f;
	default PhysValue.UpperBounciness = 0.2f;
	default PhysValue.Friction = 1.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate GroundPoundedDelegate;
        GroundPoundedDelegate.BindUFunction(this, n"GroundPounded");
        BindOnActorGroundPounded(this, GroundPoundedDelegate);

		FlipTimeLike.BindUpdate(this, n"UpdateFlip");
		FlipTimeLike.BindFinished(this, n"FinishFlip");

		WiggleTimeLike.BindUpdate(this, n"UpdateWiggle");
		WiggleTimeLike.BindFinished(this, n"FinishWiggle");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLanded");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLanded(AHazePlayerCharacter Player, FHitResult Hit)
	{
		if (Hit.Component == TopPlatform || Hit.Component == BottomPlatform)
			PhysValue.AddImpulse(15.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (WiggleTimeLike.IsPlaying() || FlipTimeLike.IsPlaying())
			return;

		PhysValue.SpringTowards(0.f, 45.f);
		PhysValue.Update(DeltaTime);

		BoardRoot.SetRelativeRotation(FRotator(0.f, 0.f, PhysValue.Value));
	}

	UFUNCTION()
	void GroundPounded(AHazePlayerCharacter Player)
	{
		if (bFlipped)
			return;

		UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
		if (ChangeSizeComp != nullptr)
		{
			if (ChangeSizeComp.CurrentSize == ECharacterSize::Small)
				return;
		}

		HazeAkComp.HazePostEvent(GroundpoundedAudioEvent);

		UHazeMovementComponent MoveComp = UHazeMovementComponent::GetOrCreate(Player);
		if (MoveComp != nullptr)
		{
			bool bTriggerFlip = Time::GetGameTimeSince(LastGroundPoundGameTime[Player.OtherPlayer]) < 1.5f;

			UPrimitiveComponent DownHitComp = MoveComp.DownHit.Component;
			if (DownHitComp == nullptr)
				return;

			if (IsCorrectPlayerOnCorrectPlatform(Player, DownHitComp))
			{
				LastGroundPoundGameTime[Player] = Time::GameTimeSeconds;
				if (bTriggerFlip)
					NetTriggerFlip();
				else
				{
					LockPlayerIntoGroundPound(Player);
					if (!WiggleTimeLike.IsPlaying())
						WiggleTimeLike.PlayFromStart();
				}
			}
		}
	}

	UFUNCTION()
	void LockPlayerIntoGroundPound(AHazePlayerCharacter Player)
	{
		if (!bLockedIntoGroundPound[Player])
		{
			bLockedIntoGroundPound[Player] = true;
			LockPlayerInGroundPoundLand(Player);
		}
	}

	UFUNCTION()
	void UnlockPlayerFromGroundPound(AHazePlayerCharacter Player)
	{
		if (bLockedIntoGroundPound[Player])
		{
			bLockedIntoGroundPound[Player] = false;
			UnlockPlayerInGroundPoundLand(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetTriggerFlip()
	{
		if (bFlipped)
			return;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UnlockPlayerFromGroundPound(Player);
			UCharacterGroundPoundComponent GroundPoundComp = UCharacterGroundPoundComponent::Get(Player);
			if (GroundPoundComp != nullptr)
			{
				GroundPoundComp.ResetState();
			}
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.PlayForceFeedback(FlipForceFeedback, false, true, n"FlipBoard");
			Player.PlayCameraShake(FlipCameraShake, 0.5f);
		}

		bFlipped = true;
		FlipTimeLike.PlayFromStart();
		SetActorEnableCollision(false);

		System::SetTimer(this, n"UnlockInput", 1.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UnlockInput()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}

		SetActorEnableCollision(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateFlip(float CurValue)
	{
		float CurRot = FMath::Lerp(0.f, 180.f, CurValue);
		BoardRoot.SetRelativeRotation(FRotator(0.f, 0.f, CurRot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishFlip()
	{
		HazeAkComp.HazePostEvent(FlipFinishAudioEvent);
		PhysValue.SnapTo(0.f, false);
		PhysValue.AddImpulse(-50.f);

		System::SetTimer(this, n"StopTicking", 8.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void StopTicking()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateWiggle(float CurValue)
	{
		float CurRot = FMath::Lerp(0.f, 5.f, CurValue);
		BoardRoot.SetRelativeRotation(FRotator(0.f, 0.f, CurRot));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishWiggle()
	{
		HazeAkComp.HazePostEvent(WiggleFinishAudioEvent);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UnlockPlayerFromGroundPound(Player);
		}
		PhysValue.SnapTo(0.f, false);
		PhysValue.AddImpulse(-35.f);
	}

	bool IsCorrectPlayerOnCorrectPlatform(AHazePlayerCharacter Player, UPrimitiveComponent DownHitComp)
	{
		if (Player == Game::GetMay() && DownHitComp == BottomPlatform)
			return true;
		if (Player == Game::GetCody() && DownHitComp == TopPlatform)
			return true;

		return false;
	}
}
