import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Arms.PlayerCutieArmsPullFeature;

class PlayerPushKillCutieCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CutiePushKill");
	default CapabilityDebugCategory = n"Cutie";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter MyPlayer;
	UInteractionComponent LeftArm;
	UInteractionComponent RightArm;
	UCutieFightCutieComponent CutieFightCutieComponent;
	ACutie Cutie;

	UButtonMashProgressHandle ButtonMashHandle;

	bool bLeftArmHasRecentInput = false;
	bool bRightArmHasRecentInput = false;
	bool HasRecentInput = false;

	bool bButtonMashHandleAdded = false;
	float BurstForceFeedbackFloat;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"Cutie", GetAttributeObject(n"Cutie"));
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ACutie CutieLocal= Cast<ACutie>(GetAttributeObject(n"Cutie"));
		if(CutieLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(CutieLocal.PhaseGlobal != 6.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Cutie.PhaseGlobal != 6.f)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cutie = Cast<ACutie>(GetAttributeObject(n"Cutie"));
		LeftArm = Cutie.LeftArm;
		RightArm = Cutie.RightArm;
		CutieFightCutieComponent = UCutieFightCutieComponent::GetOrCreate(Cutie);
		bButtonMashHandleAdded = false;

		CutieFightCutieComponent.CutieLeftArmProgress = 0;
		CutieFightCutieComponent.CutieRightArmProgress = 0;
		Cutie.LeftProgressnetworked.Value = 0;
		Cutie.RightProgressnetworked.Value = 0;

		Cutie.DoubleInteractCompArms.StartInteracting(MyPlayer);

		MyPlayer.SetAnimObjectParam(n"ABPArmPullRefenceCutieForPlayers", Cutie);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.TriggerMovementTransition(this);
		MyPlayer.BlockMovementSyncronization();

		if(MyPlayer == Game::GetMay())
		{
			CutieFightCutieComponent.IsRightArmGrabbed = true;
			RightArm.Disable(n"StartDisabled");
			Cutie.RightProgressnetworked.OverrideControlSide(MyPlayer);
			FRotator PlayerRotation = Math::MakeRotFromX(-(Cutie.ActorForwardVector).ConstrainToPlane(FVector::UpVector));
		}
		else
		{
			CutieFightCutieComponent.IsLeftArmGrabbed = true;
			LeftArm.Disable(n"StartDisabled");
			Cutie.LeftProgressnetworked.OverrideControlSide(MyPlayer);
			FRotator PlayerRotation = Math::MakeRotFromX(-(Cutie.ActorForwardVector).ConstrainToPlane(FVector::UpVector));
		}
	}


	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(ButtonMashHandle);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.UnblockMovementSyncronization();
		MyPlayer.DetachFromActor(EDetachmentRule::KeepWorld);
		Cutie.StopConstantCameraShake();
		MyPlayer.SetCapabilityAttributeObject(n"Cutie", nullptr);

		UPlayerCutieArmsPullFeature PlayerFeature = UPlayerCutieArmsPullFeature::Get(MyPlayer);

		if(MyPlayer == Game::GetMay())
		{
			CutieFightCutieComponent.IsRightArmGrabbed = false;
			RightArm.Enable(n"StartDisabled");

			if(PlayerFeature !=nullptr)
				MyPlayer.PlayEventAnimation(Animation = PlayerFeature.MayExit.Sequence);
		}
		else
		{	
			CutieFightCutieComponent.IsLeftArmGrabbed = false;
			LeftArm.Enable(n"StartDisabled");
			if(PlayerFeature !=nullptr)
				MyPlayer.PlayEventAnimation(Animation = PlayerFeature.CodyExit.Sequence);
		}
	}

	UFUNCTION()
	void AddButtonMashHandle()
	{
		if(bButtonMashHandleAdded)
			return;
		
		bButtonMashHandleAdded = true;
		if(MyPlayer == Game::GetMay())
		{
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(MyPlayer, RightArm, NAME_None, FVector(-20,0,-10));
			ButtonMashHandle.bIsExclusive = true;
		}
		else
		{
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(MyPlayer, LeftArm, NAME_None, FVector(-20,0,-10));
			ButtonMashHandle.bIsExclusive = true;
		}
	}



	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"EdgeHang";
		MyPlayer.RequestLocomotion(Locomotion);

		if(Cutie.bArmDoubleInteractComplete == false)
			return;

		AddButtonMashHandle();
		float MashRate = ButtonMashHandle.MashRateControlSide;

		ButtonMashHandle.Progress += (MashRate /25) * DeltaTime ;
		ButtonMashHandle.Progress -= 0.12 * DeltaTime ;
		HasRecentInput = ButtonMashHandle.HasRecentInput();

		//PrintToScreen(" " + CutieFightCutieComponent.CutieTotalEarProgress);
		PlayerForcefeedbackBurst(DeltaTime);
		if(ButtonMashHandle.HasRecentInput())
		{
			PlayerInputIsValid();
		}

		if(MyPlayer.HasControl())
		{
			if(MyPlayer == Game::GetCody())
			{
				CutieFightCutieComponent.CutieLeftArmProgress = ButtonMashHandle.Progress;
				Cutie.LeftProgressnetworked.Value = ButtonMashHandle.Progress;
				CutieFightCutieComponent.LeftArmHasRecentInput = bLeftArmHasRecentInput;

				if(bLeftArmHasRecentInput != HasRecentInput)
				{
					NetSendLeftArmRecent(HasRecentInput);
				}
			}
			else
			{
				CutieFightCutieComponent.CutieRightArmProgress = ButtonMashHandle.Progress;
				Cutie.RightProgressnetworked.Value = ButtonMashHandle.Progress;
				CutieFightCutieComponent.RightArmHasRecentInput = bRightArmHasRecentInput;

				if(bRightArmHasRecentInput != HasRecentInput)
				{
					NetSendRightArmRecent(HasRecentInput);
				}
			}
		}
		else
		{
			if(MyPlayer == Game::GetCody())
			{
				CutieFightCutieComponent.CutieLeftArmProgress = Cutie.LeftProgressnetworked.Value;
				ButtonMashHandle.Progress = Cutie.LeftProgressnetworked.Value;
				CutieFightCutieComponent.LeftArmHasRecentInput = bLeftArmHasRecentInput;
			}
			else
			{
				CutieFightCutieComponent.CutieRightArmProgress = Cutie.RightProgressnetworked.Value;
				ButtonMashHandle.Progress = Cutie.RightProgressnetworked.Value;
				CutieFightCutieComponent.RightArmHasRecentInput = bRightArmHasRecentInput;
			}
		}

		if(ButtonMashHandle.Progress >= 1)
		{
			//PrintToScreen("Player:" + MyPlayer + " Done");
			CutieFightCutieComponent.PlayersFinishedButtonMashingArms[MyPlayer] = true;
		}
		else 
		{
			//PrintToScreen("Player:" + MyPlayer + "Not Done");
			CutieFightCutieComponent.PlayersFinishedButtonMashingArms[MyPlayer] = false;
		}
	}

	UFUNCTION(NetFunction)
	void NetSendLeftArmRecent(bool RecentInput)
	{
		bLeftArmHasRecentInput = RecentInput;
	}
	UFUNCTION(NetFunction)
	void NetSendRightArmRecent(bool RecentInput)
	{
		bRightArmHasRecentInput = RecentInput;
	}

	UFUNCTION()
	void PlayerInputIsValid()
	{
		MyPlayer.SetFrameForceFeedback(0, ButtonMashHandle.Progress/56 + 0.02);
	}
	UFUNCTION()
	void PlayerForcefeedbackBurst(float DeltaTime)
	{
		BurstForceFeedbackFloat += DeltaTime * 0.75 + ButtonMashHandle.Progress/85;
		if(BurstForceFeedbackFloat > 1.0)
		{
			Cutie.PlayForceFeedbackBurst(MyPlayer);
			BurstForceFeedbackFloat = 0;
		}
	}
}