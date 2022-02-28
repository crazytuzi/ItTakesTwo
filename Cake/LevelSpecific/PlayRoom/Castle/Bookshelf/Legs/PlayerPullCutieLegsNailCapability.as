import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Legs.PlayerCutieLegPullFeature;


class PlayerPullCutieLegsNailCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CutiePullLegsCapablity");
	default CapabilityDebugCategory = n"Cutie";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;


	AHazePlayerCharacter MyPlayer;
	UInteractionComponent LeftLeg;
	UInteractionComponent RightLeg;
	ACutie Cutie;
	UCutieFightCutieComponent CutieFightCutieComponent;
	UButtonMashProgressHandle ButtonMashHandle;


	bool bLeftLegHasRecentInput = false;
	bool bRightLegHasRecentInput = false;
	bool HasRecentInput = false;

	bool bButtonMashHandleAdded = false;
	float BurstForceFeedbackFloat;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MyPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}
/*
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"Cutie", GetAttributeObject(n"Cutie"));
	}
*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ACutie CutieLocal= Cast<ACutie>(GetAttributeObject(n"Cutie"));
		if(CutieLocal == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if(CutieLocal.PhaseGlobal != 4.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Cutie.PhaseGlobal != 4.f)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cutie = Cast<ACutie>(GetAttributeObject(n"Cutie"));
		LeftLeg = Cutie.LeftLeg;
		RightLeg = Cutie.RightLeg;
		CutieFightCutieComponent = UCutieFightCutieComponent::GetOrCreate(Cutie);
		bButtonMashHandleAdded = false;

		CutieFightCutieComponent.CutieLeftLegProgress = 0;
		CutieFightCutieComponent.CutieRightLegProgress = 0;
		Cutie.LeftProgressnetworked.Value = 0;
		Cutie.RightProgressnetworked.Value = 0;

		Cutie.DoubleInteractCompLegs.StartInteracting(MyPlayer);

		MyPlayer.SetAnimObjectParam(n"ABPLegPullRefenceCutieForPlayers", Cutie);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.TriggerMovementTransition(this);
		MyPlayer.BlockMovementSyncronization();
		Cutie.SetAnimBoolParam(n"AnyPlayerEnterLeg", true);

		if(MyPlayer == Game::GetCody())
		{
			CutieFightCutieComponent.IsLeftLegGrabbed = true;
			MyPlayer.SetAnimBoolParam(n"CodyEnterLeftLeg", true);
			LeftLeg.Disable(n"StartDisabled");
			Cutie.LeftProgressnetworked.OverrideControlSide(MyPlayer);
		}

		if(MyPlayer == Game::GetMay())
		{
			CutieFightCutieComponent.IsRightLegGrabbed = true;
			MyPlayer.SetAnimBoolParam(n"MayEnterRightLeg", true);
			RightLeg.Disable(n"StartDisabled");
			Cutie.RightProgressnetworked.OverrideControlSide(MyPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		StopButtonMash(ButtonMashHandle);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.UnblockMovementSyncronization();
		Cutie.StopConstantCameraShake();
		Cutie.SetAnimBoolParam(n"AnyPlayerExitLeg", true);
		MyPlayer.SetCapabilityAttributeObject(n"Cutie", nullptr);

		UPlayerCutieLegPullFeature PlayerFeature = UPlayerCutieLegPullFeature::Get(MyPlayer);

		if(MyPlayer == Game::GetCody())
		{
		//	MyPlayer.SetAnimBoolParam(n"CodyExitLeftLeg", true);
			if(PlayerFeature != nullptr)
				MyPlayer.PlayEventAnimation(Animation = PlayerFeature.LocalCodyExit.Sequence);

			LeftLeg.Enable(n"StartDisabled");
			CutieFightCutieComponent.IsLeftLegGrabbed = false;
			CutieFightCutieComponent.LeftHasRecentInput = false;

			if(CutieFightCutieComponent.PlayersFinishedButtonMashingLegs[MyPlayer] = false)
			{
				if(PlayerFeature != nullptr)
					MyPlayer.PlayEventAnimation(Animation = PlayerFeature.LocalCodyExit.Sequence);
			}
		}

		if(MyPlayer == Game::GetMay())
		{
		//	MyPlayer.SetAnimBoolParam(n"MayExitRightLeg", true);
			if(PlayerFeature != nullptr)
				MyPlayer.PlayEventAnimation(Animation = PlayerFeature.LocalMayExit.Sequence);

			RightLeg.Enable(n"StartDisabled");
			CutieFightCutieComponent.IsRightLegGrabbed = false;
			CutieFightCutieComponent.RightHasRecentInput = false;
		
			if(CutieFightCutieComponent.PlayersFinishedButtonMashingLegs[MyPlayer] = false)
			{
				if(PlayerFeature != nullptr)
					MyPlayer.PlayEventAnimation(Animation = PlayerFeature.LocalMayExit.Sequence);
			}
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
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(MyPlayer, Cutie.Mesh, Cutie.Mesh.GetSocketBoneName(n"RightLeg"), FVector(0, 0, -30));
			ButtonMashHandle.bIsExclusive = true;
		}
		else
		{
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(MyPlayer, Cutie.Mesh, Cutie.Mesh.GetSocketBoneName(n"LeftLeg"), FVector(0, 0, 0));
			ButtonMashHandle.bIsExclusive = true;
		}
	}


	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"LegPull";
		MyPlayer.RequestLocomotion(Locomotion);

		if(Cutie.bLegDoubleInteractComplete == false)
			return;

		AddButtonMashHandle();
		float MashRate = ButtonMashHandle.MashRateControlSide;

		ButtonMashHandle.Progress += (MashRate /20) * DeltaTime ;
		ButtonMashHandle.Progress -= 0.15 * DeltaTime ;
		HasRecentInput = ButtonMashHandle.HasRecentInput();
		//PrintToScreen(" " + CutieFightCutieComponent.CutieTotalEarProgress);
		//PrintToScreen("bLeftLegHasRecentInput   " + bLeftLegHasRecentInput);
		//PrintToScreen("bRightLegHasRecentInput   " + bRightLegHasRecentInput);
		//PrintToScreen("CutieFightCutieComponent.LeftHasRecentInput   " + CutieFightCutieComponent.LeftHasRecentInput);
		//PrintToScreen("CutieFightCutieComponent.RightHasRecentInput   " + CutieFightCutieComponent.RightHasRecentInput);

		PlayerForcefeedbackBurst(DeltaTime);
		if(ButtonMashHandle.HasRecentInput())
		{
			PlayerInputIsValid();
		}

		if(MyPlayer.HasControl())
		{
			if(MyPlayer == Game::GetCody())
			{
				CutieFightCutieComponent.CutieLeftLegProgress = ButtonMashHandle.Progress;
				Cutie.LeftProgressnetworked.Value = ButtonMashHandle.Progress;
				CutieFightCutieComponent.LeftHasRecentInput = bLeftLegHasRecentInput;

				if(bLeftLegHasRecentInput != HasRecentInput)
				{
					NetSendLeftLegRecent(HasRecentInput);
				}
			}
			else
			{
				CutieFightCutieComponent.CutieRightLegProgress = ButtonMashHandle.Progress;
				Cutie.RightProgressnetworked.Value = ButtonMashHandle.Progress;
				CutieFightCutieComponent.RightHasRecentInput = bRightLegHasRecentInput;

				if(bRightLegHasRecentInput != HasRecentInput)
				{
					NetSendRightLegRecent(HasRecentInput);
				}
			}
		}
		else
		{
			if(MyPlayer == Game::GetCody())
			{
				CutieFightCutieComponent.CutieLeftLegProgress = Cutie.LeftProgressnetworked.Value;
				ButtonMashHandle.Progress = Cutie.LeftProgressnetworked.Value;
				CutieFightCutieComponent.LeftHasRecentInput = bLeftLegHasRecentInput;
			}
			else
			{
				CutieFightCutieComponent.CutieRightLegProgress = Cutie.RightProgressnetworked.Value;
				ButtonMashHandle.Progress = Cutie.RightProgressnetworked.Value;
				CutieFightCutieComponent.RightHasRecentInput = bRightLegHasRecentInput;
			}
		}

		if(ButtonMashHandle.Progress >= 1)
		{
			//PrintToScreen("Player:" + MyPlayer + " Done");
			CutieFightCutieComponent.PlayersFinishedButtonMashingLegs[MyPlayer] = true;
		}
		else 
		{
			//PrintToScreen("Player:" + MyPlayer + "Not Done");
			CutieFightCutieComponent.PlayersFinishedButtonMashingLegs[MyPlayer] = false;
		}
	}

	UFUNCTION(NetFunction)
	void NetSendLeftLegRecent(bool RecentInput)
	{
		bLeftLegHasRecentInput = RecentInput;
	}
	UFUNCTION(NetFunction)
	void NetSendRightLegRecent(bool RecentInput)
	{
		bRightLegHasRecentInput = RecentInput;
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