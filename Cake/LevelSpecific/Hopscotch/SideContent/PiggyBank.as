import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.LevelSpecific.Hopscotch.SideContent.PiggyBankCoin;
import Vino.Animations.LockIntoAnimation;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Pickups.PlayerPickupComponent;
import Vino.Movement.Components.GroundPound.GroundPoundThroughComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.HopscotchVOBank;
import Vino.Camera.Components.WorldCameraShakeComponent;
class APiggyBank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase DestructionMesh;
	default DestructionMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UGroundPoundThroughComponent GroundPoundThroughComponent;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UWorldCameraShakeComponent CamShakeComp;

	bool bPiggyFull = false;

	UPROPERTY()
	TArray<APiggyBankCoin> PiggyBankCoinArray;

	int CoinsInPiggy = 0;

	bool bHasCrushedPiggy = false;

	AHazePlayerCharacter PlayerInteracting;

	APiggyBankCoin CurrentCoin;

	UPROPERTY()
	UAnimSequence PiggyMH;

	UPROPERTY()
	UAnimSequence PiggyInsert;

	UPROPERTY()
	UAnimSequence PiggyFull;

	UPROPERTY()
	UAnimSequence PiggyBackMH;

	UPROPERTY()
	UAnimSequence CrushPigAnim;

	UPROPERTY()
	UAnimSequence MayInsertCoinAnim;

	UPROPERTY()
	UAnimSequence CodyInsertCoinAnim;

	UPROPERTY()
	UHopscotchVOBank VoBank;

	FName PigFullBarkToPlay;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PiggyIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PiggyBackIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopPiggyIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopPiggyBackIdleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SmashPiggyAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent InsertCoinAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PiggyFullAudioEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		GroundPoundThroughComponent.OnActorGroundPoundedThrough.AddUFunction(this, n"OnGroundPounded");
		//GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
		GroundPoundThroughComponent.DisablePoundThrough();
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

		FHazeTriggerCondition TriggerCondition;
		TriggerCondition.bOnlyCheckOnPlayerControl = true;
		TriggerCondition.Delegate.BindUFunction(this, n"CanPlayerInsertCoin");
		InteractionComp.AddTriggerCondition(n"CanPlayerInsertCoin", TriggerCondition);
		
		for(auto Player : Game::GetPlayers())
			InteractionComp.DisableForPlayer(Player, n"CoinRequired");
		
		for(auto Coin : PiggyBankCoinArray)
			Coin.CoinWasPickedUpEvent.AddUFunction(this, n"CoinWasPickedUp");

		PlayPiggyMH();
		HazeAkComp.HazePostEvent(PiggyIdleAudioEvent);
	}

	void PlayPiggyMH()
	{
		FHazePlaySlotAnimationParams PlaySlotAnimParams;
		PlaySlotAnimParams.bLoop = true;
		PlaySlotAnimParams.Animation = PiggyMH;
		Mesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), PlaySlotAnimParams);
	}

	void PlayPiggyInsert()
	{
		FHazePlaySlotAnimationParams PlaySlotAnimParams;
		PlaySlotAnimParams.bLoop = false;
		PlaySlotAnimParams.Animation = PiggyInsert;
		FHazeAnimationDelegate BlendedOut;
		BlendedOut.BindUFunction(this, n"OnPiggyInsertEnded");
		Mesh.PlaySlotAnimation(FHazeAnimationDelegate(), BlendedOut, PlaySlotAnimParams);
	}

	UFUNCTION()
	void OnPiggyInsertEnded()
	{
		if (IsPiggyFull())
		{
			PlayPiggyFull();
			AudioPiggyOnBack();
			GroundPoundThroughComponent.EnablePoundThrough();
		}
		else
		{
			PlayPiggyMH();
			SetInteractionPointEnabled(true);
		}
	}

	void PlayPiggyFull()
	{
		FHazePlaySlotAnimationParams PlaySlotAnimParams;
		PlaySlotAnimParams.bLoop = false;
		PlaySlotAnimParams.Animation = PiggyFull;
		FHazeAnimationDelegate BlendedOut;
		BlendedOut.BindUFunction(this, n"OnPiggyFullEnded");
		Mesh.PlaySlotAnimation(FHazeAnimationDelegate(), BlendedOut, PlaySlotAnimParams);
		UHazeAkComponent::HazePostEventFireForget(PiggyFullAudioEvent, GetActorTransform());
	}

	UFUNCTION()
	void OnPiggyFullEnded()
	{
		PlayPiggyBackMH();
	}

	void PlayPiggyBackMH()
	{
		FHazePlaySlotAnimationParams PlaySlotAnimParams;
		PlaySlotAnimParams.bLoop = true;
		PlaySlotAnimParams.Animation = PiggyBackMH;
		Mesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), PlaySlotAnimParams);
		HazeAkComp.HazePostEvent(StopPiggyIdleAudioEvent);
		HazeAkComp.HazePostEvent(PiggyBackIdleAudioEvent);
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		if(!IsPiggyFull())
			return;

		if (!bHasCrushedPiggy)
		{
			bHasCrushedPiggy = true;
			Mesh.SetHiddenInGame(true);
			Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			DestructionMesh.SetHiddenInGame(false);
			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = CrushPigAnim;
			AnimParams.bLoop = false;
			AnimParams.bPauseAtEnd = true;
			DestructionMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimParams);
			AudioPiggyDestroyed();
			HazeAkComp.HazePostEvent(StopPiggyBackIdleAudioEvent);
			HazeAkComp.HazePostEvent(SmashPiggyAudioEvent);

			for (auto CurrPlayer : Game::Players)
				Online::UnlockAchievement(Player, n"PiggyBank");

			FName Bark = Player == Game::GetCody() ? n"FoghornDBPlayRoomHopscotchPigBankCodySmashMay" : n"FoghornDBPlayRoomHopscotchPigBankMaySmashCody";
			PlayFoghornVOBankEvent(VoBank, Bark);

			ForceFeedbackComp.Play();
			CamShakeComp.Play();
		}
	}

	UFUNCTION(CallInEditor)
	void SetCoinArray()
	{
		GetAllActorsOfClass(PiggyBankCoinArray);
	}

	UFUNCTION()
	void CoinWasPickedUp(AHazePlayerCharacter Player, bool bWasPickedUp)
	{
		bWasPickedUp ? InteractionComp.EnableForPlayer(Player, n"CoinRequired") : InteractionComp.DisableForPlayer(Player, n"CoinRequired");
	}

	UFUNCTION(NotBlueprintCallable)
	bool CanPlayerInsertCoin(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		return !PlayerCharacter.IsPlayingAnimAsSlotAnimation(PlayerCharacter.IsCody() ? CodyInsertCoinAnim : MayInsertCoinAnim);
	}

	UFUNCTION()
	void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(Player);
		CurrentCoin = Cast<APiggyBankCoin>(PickupComp.CurrentPickup); 
		
		if (CurrentCoin != nullptr)
		{
			CoinsInPiggy++;
			IsPiggyFull();
			PlayPiggyInsert();
			PlayCharacterCoinAnim(Player);
			AudioPutInCoinStart();
			SetInteractionPointEnabled(false);
			Player.PlayerHazeAkComp.HazePostEvent(InsertCoinAudioEvent);

			if (CoinsInPiggy == PiggyBankCoinArray.Num())
			{
				PigFullBarkToPlay = Player == Game::GetCody() ? n"FoghornDBPlayRoomHopscotchPigBankLastCoinCody" : n"FoghornDBPlayRoomHopscotchPigBankLastCoinMay";
				System::SetTimer(this, n"PlayPigFullVo", 1.5f, false);
			}
		}
	}

	void PlayPigFullVo()
	{
		PlayFoghornVOBankEvent(VoBank, PigFullBarkToPlay);
	}

	void SetInteractionPointEnabled(bool bEnable)
	{
		if(bEnable)
			InteractionComp.Enable(n"PiggyDisable");
		else 
			InteractionComp.Disable(n"PiggyDisable");
	}

	void PlayCharacterCoinAnim(AHazePlayerCharacter Player)
	{
		PlayerInteracting = Player;
		Player.SmoothSetLocationAndRotation(InteractionComp.WorldLocation, InteractionComp.WorldRotation);
		FHazePlaySlotAnimationParams PlaySlotAnimParams;
		PlaySlotAnimParams.Animation = Game::GetCody() == Player ? CodyInsertCoinAnim : MayInsertCoinAnim;
		FHazeAnimationDelegate BlendedOut;
		BlendedOut.BindUFunction(this, n"OnInsertCoinEnded");
		LockIntoAnimation(PlayerInteracting, this);
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendedOut, PlaySlotAnimParams);
	}

	UFUNCTION()
	void OnInsertCoinEnded()
	{
		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(PlayerInteracting);
		UnlockFromAnimation(PlayerInteracting, this);	
		PickupComp.ForceDrop(false, false);
	    CurrentCoin.DisableCoin();
		AudioPutInCoinEnd();
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{
		if(!IsPiggyFull())
			return;

		AudioLandOnBelly();
	}

	bool IsPiggyFull()
	{
		return CoinsInPiggy == PiggyBankCoinArray.Num();
	}

	// When the coin animation starts
	void AudioPutInCoinStart()
	{
		
	}

	// When the coin animation ends
	void AudioPutInCoinEnd()
	{
		
	}

	// When the Piggy is full and falls on his back
	void AudioPiggyOnBack()
	{
		
	}

	// When a player trigger an impact on the pig. Only triggers if the Piggy is full
	void AudioLandOnBelly()
	{
		
	}

	// :( 
	void AudioPiggyDestroyed()
	{
		
	}
}