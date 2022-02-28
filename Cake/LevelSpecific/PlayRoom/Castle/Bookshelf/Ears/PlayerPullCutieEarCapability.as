import Vino.Movement.Components.MovementComponent;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Cutie;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.Ears.PlayerCutieEarsFeature;


class PlayerPullCutieEarCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Cutie");
	default CapabilityDebugCategory = n"Cutie";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter MyPlayer;
	UInteractionComponent LeftEar;
	UInteractionComponent RightEar;
	ACutie Cutie;
	UCutieFightCutieComponent CutieFightCutieComponent;
	UButtonMashProgressHandle ButtonMashHandle;
	bool bButtonMashHandleAdded = false;
	bool bCancelPressed = false;
	float BurstForceFeedbackFloat;

	bool bLeftEarHasRecentInput = false;
	bool bRightEarHasRecentInput = false;
	bool HasRecentInput = false;

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
		if(CutieLocal.PhaseGlobal != 2.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Cutie.PhaseGlobal != 2.f)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		if(Cutie.bEarDoubleInteractComplete == true)
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
		if(bCancelPressed)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bCancelPressed = false;
		Cutie = Cast<ACutie>(ActivationParams.GetObject(n"Cutie"));

		LeftEar = Cutie.LeftEar;
		RightEar = Cutie.RightEar;
		CutieFightCutieComponent = UCutieFightCutieComponent::GetOrCreate(Cutie);
		bButtonMashHandleAdded = false;

		//Cutie.EarActivate = true;
		//Cutie.OnPlayerGrabbedEar.Broadcast(MyPlayer);
		Cutie.DoubleInteractCompEars.StartInteracting(MyPlayer);

		MyPlayer.SetAnimObjectParam(n"ABPEarPullRefenceCutieForPlayers", Cutie);
		MyPlayer.BlockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.TriggerMovementTransition(this);
		MyPlayer.BlockMovementSyncronization();

		if(MyPlayer == Game::GetMay())
		{
			MyPlayer.SmoothSetLocationAndRotation(Cutie.LeftEar.GetWorldLocation(), Cutie.LeftEar.GetWorldRotation()); 
			Cutie.LeftProgressnetworked.OverrideControlSide(MyPlayer);
			LeftEar.Disable(n"InterationStarted");
			CutieFightCutieComponent.bIsLeftEarGrabbed = true;
		}
		else
		{
			MyPlayer.SmoothSetLocationAndRotation(Cutie.RightEar.GetWorldLocation(), Cutie.RightEar.GetWorldRotation());
			Cutie.RightProgressnetworked.OverrideControlSide(MyPlayer);
			RightEar.Disable(n"InterationStarted");
			CutieFightCutieComponent.bIsRightEarGrabbed = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		MyPlayer.UnblockMovementSyncronization();
		MyPlayer.StopBlendSpace();
		Cutie.StopForceFeedback(MyPlayer);
		Cutie.StopConstantCameraShake();
		MyPlayer.SetCapabilityAttributeObject(n"Cutie", nullptr);
		UPlayerCutieEarsFeature PlayerFeature = UPlayerCutieEarsFeature::Get(MyPlayer);

		CutieFightCutieComponent.CutieLeftEarProgress = 0;
		CutieFightCutieComponent.CutieRightEarProgress = 0;
		Cutie.LeftProgressnetworked.Value = 0;
		Cutie.RightProgressnetworked.Value = 0;

		//Consume cancel action this frame to avoid groundpound when exiting
		MyPlayer.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		if(bButtonMashHandleAdded)
			StopButtonMash(ButtonMashHandle);

		if(MyPlayer == Game::GetMay())
		{
			CutieFightCutieComponent.bIsLeftEarGrabbed = false;
			LeftEar.Enable(n"InterationStarted");
			Cutie.NetOnCancledEarInteraction(Cutie.LeftEar, MyPlayer);
			if(CutieFightCutieComponent.PlayersFinishedButtonMashingEars[MyPlayer] = false)
			{
				if(PlayerFeature != nullptr)
					MyPlayer.PlayEventAnimation(Animation = PlayerFeature.MayExit.Sequence);
			}
		}
		else
		{
			CutieFightCutieComponent.bIsRightEarGrabbed = false;
			RightEar.Enable(n"InterationStarted");
			Cutie.NetOnCancledEarInteraction(Cutie.RightEar, MyPlayer);
			if(CutieFightCutieComponent.PlayersFinishedButtonMashingEars[MyPlayer] = false)
			{	
				if(PlayerFeature != nullptr)
					MyPlayer.PlayEventAnimation(Animation = PlayerFeature.CodyExit.Sequence);
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
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(MyPlayer, Cutie.Mesh, Cutie.Mesh.GetSocketBoneName(n"LeftEarLobe2"), FVector(0, 0, 0));
			ButtonMashHandle.bIsExclusive = true;
		}
		else
		{
			ButtonMashHandle = StartButtonMashProgressAttachToComponent(MyPlayer, Cutie.Mesh, Cutie.Mesh.GetSocketBoneName(n"RightEarLobe2"), FVector(0, 0, 0));
			ButtonMashHandle.bIsExclusive = true;
		}
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bCancelPressed)
			return;

		//PrintToScreen("LeftEarRecentInput " + CutieFightCutieComponent.LeftEarHasRecentInput);
		//PrintToScreen("RightEarRecentInput " + CutieFightCutieComponent.RightEarHasRecentInput);

		FHazeRequestLocomotionData Locomotion;
		Locomotion.AnimationTag = n"TowerHang";
		MyPlayer.RequestLocomotion(Locomotion);

		if(WasActionStarted(ActionNames::Cancel) && Cutie.DoubleInteractCompEars.CanPlayerCancel(MyPlayer))
		{
			bCancelPressed = true;
			if(MyPlayer == Game::GetCody())
				Cutie.OnCancelInteractingEar(LeftEar, MyPlayer);
			else
				Cutie.OnCancelInteractingEar(RightEar, MyPlayer);
			
			return;
		}

		if(Cutie.bEarDoubleInteractComplete == false)
			return;


		AddButtonMashHandle();
		float MashRate = ButtonMashHandle.MashRateControlSide;
		ButtonMashHandle.Progress += (MashRate /20) * DeltaTime ;
		ButtonMashHandle.Progress -= 0.15 * DeltaTime ;
		HasRecentInput = ButtonMashHandle.HasRecentInput();
		//Print("" + MyPlayer + " Capbility" + ButtonMashHandle.Progress);
		//PrintToScreen(" " + CutieFightCutieComponent.CutieTotalEarProgress);

		PlayerForcefeedbackBurst(DeltaTime);
		if(ButtonMashHandle.HasRecentInput())
		{
			PlayerInputIsValid();
		}

		if(MyPlayer.HasControl())
		{
			if(MyPlayer == Game::GetMay())
			{
				CutieFightCutieComponent.CutieLeftEarProgress = ButtonMashHandle.Progress;
				Cutie.LeftProgressnetworked.Value = ButtonMashHandle.Progress;
				CutieFightCutieComponent.LeftEarHasRecentInput = bLeftEarHasRecentInput;

				if(bLeftEarHasRecentInput != HasRecentInput)
				{
					NetSendLeftEarRecent(HasRecentInput);
				}
			}
			else
			{
				CutieFightCutieComponent.CutieRightEarProgress = ButtonMashHandle.Progress;
				Cutie.RightProgressnetworked.Value = ButtonMashHandle.Progress;
				CutieFightCutieComponent.RightEarHasRecentInput = bRightEarHasRecentInput;

				if(bRightEarHasRecentInput != HasRecentInput)
				{
					NetSendRightEarRecent(HasRecentInput);
				}
			}
		}
		else
		{
			if(MyPlayer == Game::GetMay())
			{
				CutieFightCutieComponent.CutieLeftEarProgress = Cutie.LeftProgressnetworked.Value;
				ButtonMashHandle.Progress = Cutie.LeftProgressnetworked.Value;
				CutieFightCutieComponent.LeftEarHasRecentInput = bLeftEarHasRecentInput;
			}

			else
			{
				CutieFightCutieComponent.CutieRightEarProgress = Cutie.RightProgressnetworked.Value;
				ButtonMashHandle.Progress = Cutie.RightProgressnetworked.Value;
				CutieFightCutieComponent.RightEarHasRecentInput = bRightEarHasRecentInput;
			}
		}

		if(ButtonMashHandle.Progress >= 1)
		{
			//PrintToScreen("Player:" + MyPlayer + " Done");
			CutieFightCutieComponent.PlayersFinishedButtonMashingEars[MyPlayer] = true;
		}
		else 
		{
			//PrintToScreen("Player:" + MyPlayer + "Not Done");
			CutieFightCutieComponent.PlayersFinishedButtonMashingEars[MyPlayer] = false;
		}
	}

	
	UFUNCTION(NetFunction)
	void NetSendLeftEarRecent(bool RecentInput)
	{
		bLeftEarHasRecentInput = RecentInput;
	}
	UFUNCTION(NetFunction)
	void NetSendRightEarRecent(bool RecentInput)
	{
		bRightEarHasRecentInput = RecentInput;
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