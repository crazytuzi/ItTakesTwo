import Vino.Interactions.InteractionComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

event void FMatrioshkaEvent();

class AMatrioshkaActor : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent SlapComp;

	UPROPERTY()
	AHazePlayerCharacter StuckPlayer;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Skelmesh;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VO;

	UPROPERTY()
	UAnimSequence MayEnter;

	UPROPERTY()
	UAnimSequence MayMH;

	UPROPERTY()
	UAnimSequence CodyTrapMayExit;

	UPROPERTY()
	UAnimSequence CodyTrapCodyExit;

	UPROPERTY()
	UAnimSequence CodyExit;

	UPROPERTY()
	UAnimSequence MayExit;

	UPROPERTY()
	UAnimSequence CodyEnter;

	UPROPERTY()
	UAnimSequence CodyMH;

	UPROPERTY()
	UAnimSequence MayTrapMayExit;

	UPROPERTY()
	UAnimSequence MayTrapCodyExit;

	UPROPERTY()
	UAnimSequence Enter;

	UPROPERTY()
	UAnimSequence MH;

	UPROPERTY()
	UAnimSequence Exit;

	UPROPERTY()
	UAnimSequence DollMaytrapExit;

	UPROPERTY()
	TArray<UAnimSequence>  ShakeAnim;

	UPROPERTY()
	FMatrioshkaEvent OnSlapped;

	UPROPERTY()
	FMatrioshkaEvent OnInteracted;

	float ShakeCoolDown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnActivated.AddUFunction(this, n"PlayerInteracted");
		Capability::AddPlayerCapabilityRequest(n"MatruoshkaCapability");

		SlapComp.OnActivated.AddUFunction(this, n"OnPlayerSlapped");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(n"MatruoshkaCapability");
	}

	UFUNCTION()
	void PlayerInteracted(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		StuckPlayer = Player;
		StuckPlayer.SetCapabilityAttributeObject(n"Doll", this);
		StuckPlayer.SetCapabilityActionState(n"IsEnteringDoll", EHazeActionState::Active);
		
		
		InteractComp.DisableForPlayer(Game::Cody, n"PlayerInteracted");
		InteractComp.DisableForPlayer(Game::May, n"PlayerInteracted");

		UAnimSequence PlayerAnim;

		if(Player.IsMay())
		{
			PlayerAnim = MayEnter;
			PlayFoghornVOBankEvent(VO, n"FoghornDBPlayRoomTrainStationDollTrapMay", Player);
		}
		else
		{
			PlayerAnim = CodyEnter;
			PlayFoghornVOBankEvent(VO, n"FoghornDBPlayRoomTrainStationDollTrapCody", Player);
		}

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"SetMH");

		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = PlayerAnim);

		FHazePlaySlotAnimationParams MatryoshkaParams;
		MatryoshkaParams.Animation = Enter;
		Skelmesh.PlaySlotAnimation(MatryoshkaParams);
		

		OnInteracted.Broadcast();
	}

	UFUNCTION()
	void Shake()
	{
		if (ShakeCoolDown < System::GameTimeInSeconds)
		{
			FHazePlaySlotAnimationParams Params;
			int Index = FMath::RandRange(0,1);
			Params.Animation = ShakeAnim[Index];

			Skelmesh.PlaySlotAnimation(Params);
			
			ShakeCoolDown = System::GameTimeInSeconds + Params.Animation.SequenceLength + 0.25f;
		}
		
	}

	UFUNCTION()
	void SetMH()
	{
		FHazePlaySlotAnimationParams PlayerParams;
		PlayerParams.BlendTime = 0;

		if(StuckPlayer.IsMay())
		{
			PlayerParams.Animation = MayMH;	
		}
		else
		{
			PlayerParams.Animation = CodyMH;	
		}

		PlayerParams.bLoop = true;

		StuckPlayer.PlaySlotAnimation(PlayerParams);
		StuckPlayer.SetCapabilityActionState(n"IsEnteringDoll", EHazeActionState::Inactive);

		FHazePlaySlotAnimationParams MatryoshkaParams;
		MatryoshkaParams.BlendTime = 0;
		MatryoshkaParams.Animation = MH;
		MatryoshkaParams.bLoop = true;
		Skelmesh.PlaySlotAnimation(MatryoshkaParams);
		SlapComp.Enable(n"StartDisabled");

		if(StuckPlayer.OtherPlayer.IsCody())
		{
			SlapComp.SetExclusiveForPlayer(EHazePlayer::Cody, true);
		}
		else
		{
			SlapComp.SetExclusiveForPlayer(EHazePlayer::May, true);
		}	
	}

	UFUNCTION()
	void ReleasePlayer()
	{
		StuckPlayer.SetCapabilityAttributeObject(n"Doll", nullptr);
	}

	UFUNCTION()
	void OnPlayerSlapped(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		SlapComp.Disable(n"StartDisabled");
		OnSlapped.Broadcast();

		StuckPlayer.SetCapabilityActionState(n"Slapped", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NetFunction)
	void AutoReleasePlayer()
	{
		SlapComp.Disable(n"StartDisabled");
		StuckPlayer.SetCapabilityActionState(n"IsLeavingDoll", EHazeActionState::Active);
		InteractComp.DisableForPlayer(Game::Cody, n"PlayerInteracted");
		InteractComp.DisableForPlayer(Game::May, n"PlayerInteracted");

		UAnimSequence PlayerAnim;

		if(StuckPlayer.IsMay())
		{
			PlayerAnim = MayTrapMayExit;
			PlayFoghornVOBankEvent(VO, n"FoghornDBPlayRoomTrainStationDollExpireMay", StuckPlayer);
		}
		else
		{
			PlayerAnim = CodyTrapCodyExit;
			PlayFoghornVOBankEvent(VO, n"FoghornDBPlayRoomTrainStationDollExpireCody", StuckPlayer);
		}

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"OnExited");

		StuckPlayer.PlayEventAnimation(OnBlendingOut = AnimDelegate, Animation = PlayerAnim);

		FHazePlaySlotAnimationParams MatryoshkaParams;
		MatryoshkaParams.Animation = Exit;
		Skelmesh.PlaySlotAnimation(MatryoshkaParams);
	}

	UFUNCTION(NetFunction)
	void PlayOnSlappedAnim()
	{
		StuckPlayer.SetCapabilityActionState(n"IsLeavingDoll", EHazeActionState::Active);
		InteractComp.DisableForPlayer(Game::Cody, n"PlayerInteracted");
		InteractComp.DisableForPlayer(Game::May, n"PlayerInteracted");

		UAnimSequence PlayerAnim;

		if(StuckPlayer.IsMay())
		{
			PlayerAnim = MayTrapMayExit;
			StuckPlayer.OtherPlayer.PlayEventAnimation(Animation = MayTrapCodyExit);
			PlayFoghornVOBankEvent(VO, n"FoghornDBPlayRoomTrainStationDollRescueMay", StuckPlayer);
		}
		else
		{
			PlayerAnim = CodyTrapCodyExit;
			StuckPlayer.OtherPlayer.PlayEventAnimation(Animation = CodyTrapMayExit);
			PlayFoghornVOBankEvent(VO, n"FoghornDBPlayRoomTrainStationDollRescueCody", StuckPlayer);
		}

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"OnExited");

		StuckPlayer.PlayEventAnimation(OnBlendingOut = AnimDelegate, Animation = PlayerAnim);

		FHazePlaySlotAnimationParams MatryoshkaParams;
		MatryoshkaParams.Animation = DollMaytrapExit;
		Skelmesh.PlaySlotAnimation(MatryoshkaParams);
	}

	UFUNCTION()
	void OnExited()
	{
		StuckPlayer.SetCapabilityActionState(n"IsLeavingDoll", EHazeActionState::Inactive);
		
		InteractComp.EnableForPlayer(Game::Cody, n"PlayerInteracted");
		InteractComp.EnableForPlayer(Game::May, n"PlayerInteracted");

		StuckPlayer.SetCapabilityAttributeObject(n"Doll", nullptr);
		OnInteracted.Broadcast();
	}
}