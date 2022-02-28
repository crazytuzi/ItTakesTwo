import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Vino.Pierceables.PierceableComponent;
import Cake.LevelSpecific.Shed.NailMine.PlayerPiercedComponent;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailWeaponStatics;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.Movement.MovementSystemTags;
import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.Shed.Main.NailThrowWheel;

class UPlayerPiercedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PiercedPlayer");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"PiercedPlayer";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;
	
	AHazePlayerCharacter Player;
	UPierceableComponent PierceableComp;
	UPlayerPiercedComponent PlayerPiercedComp;
	UButtonMashProgressHandle ButtonMash;
	UPlayerHealthComponent HealthComp = nullptr;
	ANailWeaponActor Nail;

	private FHazeAudioEventInstance PlayerHitByNailLoopInstance;
	bool bButtonMashActive = false;
	bool bNailWasRecalled = false;
	bool bPlayerIsPierced = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PierceableComp = UPierceableComponent::GetOrCreate(Player);
		PierceableComp.ConsecutivelyPierced.AddUFunction(this, n"PlayerWasHit");
		PlayerPiercedComp = UPlayerPiercedComponent::GetOrCreate(Player);
		HealthComp = UPlayerHealthComponent::Get(Player); 
	}

	UFUNCTION()
	void PlayerWasHit(AActor ActorDoingThePiercing, AActor ActorBeingPierced, UPrimitiveComponent CompBeingPiercead, FHitResult HitResult)
	{
		if (PierceableComp.IsPierced() || bPlayerIsPierced || IsBlocked() || !IsMayGrounded())
		{
			RecallNailToWielder(Game::GetCody(), Cast<ANailWeaponActor>(ActorDoingThePiercing));
		}
		else if (!IsBlocked())
		{
			Nail = Cast<ANailWeaponActor>(ActorDoingThePiercing);
			bNailWasRecalled = false;
			bPlayerIsPierced = true;
			Nail.OnNailRecalled.AddUFunction(this, n"NailWasRecalled");

			PlayerHitByNailLoopInstance = Player.PlayerHazeAkComp.HazePostEvent(PlayerPiercedComp.HitByNailEvent);

			// Play May enter pierced animation early locally
			if(!IsActive() && !IsPlayingMayAnimation_Enter() && !IsPlayingMayAnimation_MH())
			{
				PlayNailAnimation_Enter();
				FHazeAnimationDelegate OnEnterBlendedIn;
				FHazeAnimationDelegate OnEnterBlendedOut;
				OnEnterBlendedOut.BindUFunction(this, n"PlayPiercedMH");
				PlayMayAnimation_Enter(OnEnterBlendedIn, OnEnterBlendedOut);
			}

		}
	}

	UFUNCTION()
	void NailWasRecalled(const float EstimatedTravelTime)
	{
		bNailWasRecalled = true;
		bPlayerIsPierced = false;

		// This handles the blending out of the animations 
		// which might prematurely start due to us playing 
		// them as soon as the nail hits (local)
		if(HasControl())
		{
			// it is networked on Mays side in order 
			// for the events to align with the 
			// activation/deactivation of this capablity
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"DasNail", Nail);
			auto MayCrumbComp = UHazeCrumbComponent::GetOrCreate(Player);
			MayCrumbComp.LeaveAndTriggerDelegateCrumb(
				FHazeCrumbDelegate(this, n"CrumbStopEarlyEnterAnimations"),
				CrumbParams
			);
		}
	}

	UFUNCTION()
	void CrumbStopEarlyEnterAnimations(const FHazeDelegateCrumbData& CrumbData)
	{
		if(IsPlayingMayAnimation_Enter())
			Player.StopAnimationByAsset(PlayerPiercedComp.MayWasHitAnim);

		if(IsPlayingMayAnimation_MH())
			Player.StopAnimationByAsset(PlayerPiercedComp.MayMH);

		ANailWeaponActor DasNail = Cast<ANailWeaponActor>(CrumbData.GetObject(n"DasNail"));

		if(IsPlayingNailAnimation_Enter())
			DasNail.StopAnimationByAsset(PlayerPiercedComp.NailEnterAnim);

		if(IsPlayingNailAnimation_MH())
			DasNail.StopAnimationByAsset(PlayerPiercedComp.NailMH);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bPlayerIsPierced)
			return EHazeNetworkActivation::DontActivate;

		if(!PierceableComp.IsPierced())
			return EHazeNetworkActivation::DontActivate;

		if(IsPlayingMayAnimation_Exit())
			return EHazeNetworkActivation::DontActivate;

		if(HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;

		if(!IsMayGrounded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bPlayerIsPierced)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!PierceableComp.IsPierced())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bNailWasRecalled)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(HealthComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(HealthComp.RecentlyLostHealth > 0 || HealthComp.bStartedDamageCharge)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsMayGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"DasNail", Nail);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		OutParams.AddActionState(n"bNailWasRecalled");
	}

	FVector MaysScaleUponActivating = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MaysScaleUponActivating = Player.GetActorScale3D();

		Nail = Cast<ANailWeaponActor>(ActivationParams.GetObject(n"DasNail"));

		Player.TriggerMovementTransition(this);

		// Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);

		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		Player.BlockCapabilities(n"Weapon", this);
		Player.BlockCapabilities(n"NailRained", this);
		Player.BlockCapabilities(n"Tutorial", this);

		// animations might've already started as soon as the nail hit event triggered
		if(!IsPlayingMayAnimation_Enter() && !IsPlayingMayAnimation_MH())
		{
			PlayNailAnimation_Enter();

			FHazeAnimationDelegate OnEnterBlendedIn;
			FHazeAnimationDelegate OnEnterBlendedOut;
			OnEnterBlendedOut.BindUFunction(this, n"PlayerEnterButtonmash");
			PlayMayAnimation_Enter(OnEnterBlendedIn, OnEnterBlendedOut);
		}
		else
		{
			PlayerEnterButtonmash();
		}

		// attach player to rotating and translating platform
		const FHitResult& LastValidGroundData = UHazeBaseMovementComponent::Get(Player).GetLastValidGround();
		if(LastValidGroundData.Component != nullptr)
			Player.AttachToComponent(LastValidGroundData.Component, LastValidGroundData.BoneName, EAttachmentRule::KeepWorld);

		if(!IsMinigameActive())
			PlayFoghornVOBankEvent(PlayerPiercedComp.FogHornDataAsset, n"FoghornDBShedNailMay");

		Player.PlayForceFeedback(PlayerPiercedComp.ForceFeedBack, false, true, n"PlayerHammered");
		Player.SetCapabilityActionState(n"FoghornSBNailMayHammerhead", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// detach the player from the rotating platform
		Player.DetachRootComponentFromParent();

		// Stop ongoing animations that might trigger button mash
		Player.StopAnimation();
		Nail.StopAnimation();

		bButtonMashActive = false;
		if(ButtonMash != nullptr)
			ButtonMash.StopButtonMash();

		// we need to stop the button mash success animation before the nail is recalled
		Player.StopAnimation();
		Nail.StopAnimation();

		// Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);

		Player.UnblockCapabilities(n"Weapon", this);
		Player.UnblockCapabilities(n"NailRained", this);
		Player.UnblockCapabilities(n"Tutorial", this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		//////////////////////////////////////////////////////////////////////////
		// note to self: bNailWasRecalled and bPlayerIsPierced aren't reliable.
		// Both may and codys crumb trail modifiy them. You'd have to send over
		// the state on ControlPreDeactivation if you need to use it
		//////////////////////////////////////////////////////////////////////////

		// deal with some problematic ground
		// ...in case cody is in his tutorial and he refuses to recall the nail
		const bool bRecallTutorialActive = Game::GetCody().IsAnyCapabilityActive(n"Tutorial"); 
		bool bInvalidGround = IsPlayerStandingOnInvalidGround();
		if (bInvalidGround && bRecallTutorialActive)
		{
			Nail.MovementComponent.Velocity.Normalize();
			FHitResult FakeHitData = UHazeBaseMovementComponent::Get(Player).GetLastValidGround();
			FakeHitData.Normal = Nail.GetActorUpVector();
			FakeHitData.Location = Nail.GetActorLocation();
			FakeHitData.ImpactPoint = Nail.GetActorLocation();
			Nail.HandleCollision(FakeHitData);
		}

		RecallNailToWielder(Game::GetCody(), Nail);

		if (Player.PlayerHazeAkComp.HazeIsEventActive(PlayerPiercedComp.HitByNailEvent.ShortID))
		{
			Player.PlayerHazeAkComp.HazeStopEvent(PlayerHitByNailLoopInstance.PlayingID);
		}

		Nail.OnNailRecalled.UnbindObject(this);
		bPlayerIsPierced = false;
		Nail = nullptr;

		ensure(MaysScaleUponActivating == Player.GetActorScale3D());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bButtonMashActive && ButtonMash != nullptr)
		{
			ButtonMash.Progress += ButtonMash.MashRateControlSide * 0.1f * DeltaTime;
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Main_Interaction_HitByNail_DragOut_Progress", ButtonMash.Progress);
		}
	}

	UFUNCTION()
	void PlayerEnterButtonmash()
	{
		PlayPiercedMH();

		ButtonMash = StartButtonMashProgressAttachToActor(Player, Player, FVector::ZeroVector);
		ButtonMash.OnCompleted.AddUFunction(this, n"ButtonMashCompleted");
		ButtonMash.bSyncOverNetwork = true;
		bButtonMashActive = true;
	}

	UFUNCTION()
	void ButtonMashCompleted()
	{
		bButtonMashActive = false;
		ButtonMash.StopButtonMash();

		Player.PlayerHazeAkComp.HazePostEvent(PlayerPiercedComp.NailPulledOutEvent);
		PlayerHitByNailLoopInstance = Audio::GetEmptyEventInstance();
		Player.StopBlendSpace();
		if(!IsBlocked())
		{
			FHazeAnimationDelegate OnExitBlendedIn;
			FHazeAnimationDelegate OnExitBlendedOut;
			OnExitBlendedOut.BindUFunction(this, n"PlayerExitedPiercedState");
			PlayMayAnimation_Exit(OnExitBlendedIn, OnExitBlendedOut);

			PlayNailAnimation_Exit();
		}
		else
		{
			PlayerExitedPiercedState();

			PlayNailAnimation_Exit();
			Nail.StopAnimation();

			// attach it at the impact point
			const FHitResult& LastValidGroundData = UHazeBaseMovementComponent::Get(Player).GetLastValidGround();
			if(LastValidGroundData.Component != nullptr)
			{
				Nail.AttachToComponent(LastValidGroundData.Component, LastValidGroundData.BoneName, EAttachmentRule::KeepWorld);
				Nail.SetActorLocation(LastValidGroundData.ImpactPoint);
			}

			// have lie3 down flat so that it looks less wierd
			const FRotator FlatRot = FRotator(90.f, 0.f, 0.f);
			Nail.SetActorRelativeRotation(FlatRot, false, FHitResult(), false);
			// Nail.SetActorRelativeRotation(FRotator::ZeroRotator, false, FHitResult(), false);
		}
	}

	void PlayNailAnimation_Exit()
	{
		ensure(!IsPlayingNailAnimation_Exit());
		FHazeAnimationDelegate OnNailExitBlendedIn;
		FHazeAnimationDelegate OnNailExitBlendedOut;
		OnNailExitBlendedOut.BindUFunction(this, n"HandlePinnedNail");
		Nail.PlaySlotAnimation(OnNailExitBlendedIn, OnNailExitBlendedOut, PlayerPiercedComp.NailExit, false);
	}

	UFUNCTION()
	void PlayerExitedPiercedState()
	{
		bPlayerIsPierced = false;
	}

	bool IsMayGrounded() const
	{
		const auto PlayerMoveComp = UHazeBaseMovementComponent::Get(Game::GetMay());
		return PlayerMoveComp.IsGrounded();
	}

	UFUNCTION()
	void PlayPiercedMH()
	{
		if(!IsPlayingMayAnimation_MH())
			PlayMayAnimation_MH();

		if(!IsPlayingNailAnimation_MH())
			PlayNailAnimation_MH();
	}

	void PlayNailAnimation_Enter()
	{
		ensure(!IsPlayingNailAnimation_Enter());

		UPiercingComponent PiercingComp = GetPiercingComponent(Nail);
		PiercingComp.bSkipWiggleIntoPierce = true;

		auto Rule = EAttachmentRule::SnapToTarget;
		Nail.AttachToActor(Player, n"Align", Rule);
		ForceFinishPiercingWiggle(Nail);
		Nail.SetActorRelativeRotation( FRotator::ZeroRotator, false, FHitResult(), false);

		FHazeAnimationDelegate OnNailEnterBlendedIn;
		FHazeAnimationDelegate OnNailEnterBlendedOut;
		Nail.PlaySlotAnimation(OnNailEnterBlendedIn, OnNailEnterBlendedOut, PlayerPiercedComp.NailEnterAnim, BlendTime = 0.f);
	}

	void PlayNailAnimation_MH()
	{
		ensure(!IsPlayingNailAnimation_MH());
		FHazeAnimationDelegate OnNailMHBlendedIn;
		FHazeAnimationDelegate OnNailMHBlendedOut;
		Nail.PlaySlotAnimation(OnNailMHBlendedIn, OnNailMHBlendedOut, PlayerPiercedComp.NailMH, true);
	}

	UFUNCTION()
	void HandlePinnedNail()
	{
		if(Nail == nullptr)
		{
			// ensure(false);
			return;
		}

		UNailWielderComponent NailWielderComp = UNailWielderComponent::Get(Game::GetCody());
		if(NailWielderComp.IsNailBeingRecalled(Nail))
		{
			// ensure(false);
			return;
		}

		if(Nail.Mesh.IsSimulatingPhysics())
		{
			// ensure(false);
			return;
		}

		if(Nail.AttachParentActor != Player)
		{
			// ensure(false);
			return;
		}

		// attach the pulled out nail to the rotating platform which May is standing on
		const FHitResult& LastValidGroundData = UHazeBaseMovementComponent::Get(Player).GetLastValidGround();
		if(LastValidGroundData.Component != nullptr)
		{
			Nail.AttachToComponent(LastValidGroundData.Component, LastValidGroundData.BoneName, EAttachmentRule::KeepWorld);
		}

		// this exit nail animation doesn't have root motion - but the one afterwards 
		// has it. This applies a dirty rootmotion here to fix it. We'd have to change 
		// things in the statemachine to fix this in a clean way.
		const FVector OffsetDirection = Nail.GetActorQuat().GetUpVector();
		Nail.AddActorWorldOffset(OffsetDirection * -85.f);
	}

	void PlayMayAnimation_Enter(FHazeAnimationDelegate EnterBlendIn, FHazeAnimationDelegate EnterBlendOut)
	{
		ensure(!IsPlayingMayAnimation_Enter());
		Player.PlaySlotAnimation(EnterBlendIn, EnterBlendOut, PlayerPiercedComp.MayWasHitAnim, BlendTime = 0.f);
	}

	void PlayMayAnimation_MH()
	{
		ensure(!IsPlayingMayAnimation_MH());
		FHazeAnimationDelegate OnMHBlendedIn;
		FHazeAnimationDelegate OnMHBlendedOut;
		Player.PlaySlotAnimation(OnMHBlendedIn, OnMHBlendedOut, PlayerPiercedComp.MayMH, true);
	}

	void PlayMayAnimation_Exit(FHazeAnimationDelegate ExitBlendIn, FHazeAnimationDelegate ExitBlendOut)
	{
		ensure(!IsPlayingMayAnimation_Exit());
		Player.PlaySlotAnimation(ExitBlendIn, ExitBlendOut, PlayerPiercedComp.MayFinishedButtonmash);
	}

	bool IsPlayingMayAnimation_Exit() const
	{
		// return false;
		return Player.IsPlayingAnimAsSlotAnimation(PlayerPiercedComp.MayFinishedButtonmash);
	}

	bool IsPlayingNailAnimation_Exit() const
	{
		// return false;
		return Player.IsPlayingAnimAsSlotAnimation(PlayerPiercedComp.NailExit);
	}

	bool IsPlayingMayAnimation_Enter() const
	{
		// return false;
		return Player.IsPlayingAnimAsSlotAnimation(PlayerPiercedComp.MayWasHitAnim);
	}

	bool IsPlayingMayAnimation_MH() const
	{
		// return false;
		return Player.IsPlayingAnimAsSlotAnimation(PlayerPiercedComp.MayMH);
	}

	bool IsPlayingNailAnimation_Enter() const
	{
		// return false;
		return Nail.IsPlayingAnimAsSlotAnimation(PlayerPiercedComp.NailEnterAnim);
	}

	bool IsPlayingNailAnimation_MH() const
	{
		// return false;
		return Nail.IsPlayingAnimAsSlotAnimation(PlayerPiercedComp.NailMH);
	}

	bool IsPlayerStandingOnInvalidGround()
	{
		const FHitResult& LastValidGroundData = UHazeBaseMovementComponent::Get(Player).GetLastValidGround();
		if(LastValidGroundData.Component == nullptr)
			return false;

		UBreakableComponent Breakable = Cast<UBreakableComponent>(LastValidGroundData.Component);
		if(Breakable != nullptr)
		{
			// no. It might break afterwards. can't take that chance.
			return true;
		}

		AHazeActor HazyActor = Cast<AHazeActor>(LastValidGroundData.Component.Owner);
		if(HazyActor != nullptr)
		{
			if(HazyActor.IsActorDisabled())
			{
				return true;
			}
		}

		return false;
	}

	bool IsMinigameActive() const
	{
		bool bMinigameActive = false;
		TArray<ANailThrowWheel> Minigames;
		GetAllActorsOfClass(Minigames);
		if(Minigames.Num() > 0)
		{
			ensure(Minigames.Num() == 1);
			bMinigameActive = Minigames[0].WheelActive;
		}
		return bMinigameActive;
	}

//	TArray<ANailWeaponActor> Nails;
//	default Nails.SetNum(3);
//
//	void Empty() const
//	{
//		for(int i = 0; i < Nails.Num(); ++i)
//			Nails[i] == nullptr;
//	}
//
//	bool IsEmpty() const
//	{
//		for(int i = 0; i < Nails.Num(); ++i)
//		{
//			if(Nails[i] != nullptr)
//			{
//				return false;
//			}
//		}
//		return true;
//	}
//
//	bool IsPierced() const
//	{
//		for(int i = 0; i < Nails.Num(); ++i)
//		{
//			if(Nails[i] != nullptr)
//			{
//				return true;
//			}
//		}
//		return false;
//	}
//
//	void RemoveNail(UObject InNail)
//	{
//		for(int i = 0; i < Nails.Num(); ++i)
//		{
//			if(Nails[i] == InNail)
//			{
//				Nails[i] = nullptr;
//				break;
//			}
//		}
//	}
//
//	void AddNail(UObject InNail)
//	{
//		// occupy vacant slots 
//		for(int i = 0; i < Nails.Num(); ++i)
//		{
//			if(Nails[i] == nullptr)
//			{
//				Nails[i] = Cast<ANailWeaponActor>(InNail);
//				break;
//			}
//		}
//	}

}