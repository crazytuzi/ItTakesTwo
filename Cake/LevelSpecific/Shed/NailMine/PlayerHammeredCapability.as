import Cake.Weapons.Hammer.HammerableComponent;
import Cake.LevelSpecific.Shed.NailMine.PlayerHammeredComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.Environment.BreakableComponent;

class UPlayerHammeredCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HammeredPlayer");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"HammeredPlayer";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY()
	UAnimSequence HitAnimation;

	bool PlayerWasHammered = false;
	bool ButtonMashActive = false;
	
	AHazePlayerCharacter Cody;
	UHammerableComponent HammerableComp;
	UPlayerHammeredComponent PlayerHammeredComp;
	UButtonMashProgressHandle ButtonMash;
	UPlayerHealthComponent HealthComp = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cody = Cast<AHazePlayerCharacter>(Owner);

		HammerableComp = UHammerableComponent::GetOrCreate(Cody);
		HammerableComp.OnHammered.AddUFunction(this, n"PlayerWasHit");

		PlayerHammeredComp = UPlayerHammeredComponent::GetOrCreate(Cody);
		HitAnimation = PlayerHammeredComp.CodyWasHitAnim;

		HealthComp = UPlayerHealthComponent::Get(Cody); 
	}

	UFUNCTION()
	void PlayerWasHit(AActor ActorDoingTheHammering, AActor ActorBeingHammered, FComponentsBeingHammered ComponentsBeing)
	{
		// no
		if(IsBlocked())
			return;

		// no
		UHazeMovementComponent MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		if (!MoveComp.IsGrounded()) 
			return;
		
		// no! It's gonna shatter anyway
		if(StandingOnBreakable())
			return;

		// alright alright here we go
		PlayerWasHammered = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerWasHammered)
			return EHazeNetworkActivation::DontActivate;
		
		if(HealthComp.bIsDead)
			return EHazeNetworkActivation::DontActivate;

		if(StandingOnBrokenBreakable())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerWasHammered)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(HealthComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(HealthComp.RecentlyLostHealth > 0 || HealthComp.bStartedDamageCharge)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(StandingOnBrokenBreakable())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	FVector CodyScaleUponActivating = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CodyScaleUponActivating = Cody.GetActorScale3D();

		Cody.BlockCapabilities(n"Movement", this);
		Cody.BlockCapabilities(n"NailRecall", this);
		Cody.BlockCapabilities(n"NailRained", this);
		Cody.BlockCapabilities(n"Tutorial", this);
		Cody.BlockCapabilities(CapabilityTags::Interaction, this);

		FHazeAnimationDelegate OnEnterBlendedIn;
		FHazeAnimationDelegate OnEnterBlendedOut;
		OnEnterBlendedOut.BindUFunction(this, n"PlayerEnterButtonmash");
		Cody.PlaySlotAnimation(OnEnterBlendedIn, OnEnterBlendedOut, HitAnimation);

		Cody.PlayForceFeedback(PlayerHammeredComp.ForceFeedBack, false, true, n"PlayerHammered");
		Game::GetMay().SetCapabilityActionState(n"FoghornSBHammerCodyHammerhead", EHazeActionState::ActiveForOneFrame);

		Game::May.DisableOutlineByInstigator(this);
		Game::Cody.DisableOutlineByInstigator(this);
		
		PlayFoghornVOBankEvent(PlayerHammeredComp.FogHornDataAsset, n"FoghornDBShedHammerCody");		
		
		const FHitResult& LastValidGroundData = UHazeBaseMovementComponent::Get(Cody).GetLastValidGround();
		if(LastValidGroundData.Component != nullptr)
			Cody.AttachToComponent(LastValidGroundData.Component, LastValidGroundData.BoneName, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Cody.DetachRootComponentFromParent();

		// Cody.StopAnimationByAsset(HitAnimation, 0.f);
		Cody.StopAllSlotAnimations();

		if(ButtonMash != nullptr)
		{
			ButtonMash.StopButtonMash();
			if (ButtonMashActive)
			{
				ButtonMashCompleted();
			}
		}

		Cody.StopAllSlotAnimations();

		Game::Cody.EnableOutlineByInstigator(this);
		Game::May.EnableOutlineByInstigator(this);

		PlayerWasHammered = false;

		ensure(CodyScaleUponActivating == Cody.GetActorScale3D());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (ButtonMashActive && ButtonMash != nullptr)
		{
			ButtonMash.Progress += ButtonMash.MashRateControlSide * 0.1f * DeltaTime;
			Cody.SetBlendSpaceValues(0.f, ButtonMash.Progress);
		}
	}

	UFUNCTION()
	void PlayerEnterButtonmash()
	{
		Cody.PlayBlendSpace(PlayerHammeredComp.CodyBS);
		ButtonMash = StartButtonMashProgressAttachToActor(Cody, Cody, FVector::ZeroVector);
		ButtonMash.OnCompleted.AddUFunction(this, n"ButtonMashCompleted");
		ButtonMash.bSyncOverNetwork = true;
		ButtonMashActive = true;
	}

	UFUNCTION()
	void ButtonMashCompleted()
	{
		Cody.StopBlendSpace();
		ButtonMashActive = false;
		ButtonMash.StopButtonMash();
		Cody.UnblockCapabilities(n"NailRecall", this);
		
		// don't play exit animation when blocked
		if(!IsBlocked())
		{
			FHazeAnimationDelegate OnExitBlendedIn;
			FHazeAnimationDelegate OnExitBlendedOut;
			OnExitBlendedOut.BindUFunction(this, n"PlayerExitedHammeredState");
			Cody.PlaySlotAnimation(OnExitBlendedIn, OnExitBlendedOut, PlayerHammeredComp.CodyFinishedButtonmash);
		}
		else
		{
			PlayerExitedHammeredState();
		}
	}

	UFUNCTION()
	void PlayerExitedHammeredState()
	{
		Cody.UnblockCapabilities(n"Movement", this);
		Cody.UnblockCapabilities(n"NailRained", this);
		Cody.UnblockCapabilities(n"Tutorial", this);
		Cody.UnblockCapabilities(CapabilityTags::Interaction, this);

		PlayerWasHammered = false;
	}

	bool StandingOnBreakable() const
	{
		const FHitResult LastValidGroundData = UHazeBaseMovementComponent::Get(Cody).GetLastValidGround();
		if(LastValidGroundData.Component == nullptr)
			return false;

		UBreakableComponent BreakableComp = Cast<UBreakableComponent>(LastValidGroundData.Component);
		if(BreakableComp == nullptr)
			return false;

		return true;
	}

	bool StandingOnBrokenBreakable() const
	{
		const FHitResult LastValidGroundData = UHazeBaseMovementComponent::Get(Cody).GetLastValidGround();
		if(LastValidGroundData.Component == nullptr)
			return false;

		UBreakableComponent BreakableComp = Cast<UBreakableComponent>(LastValidGroundData.Component);
		if(BreakableComp == nullptr)
			return false;

		return BreakableComp.Broken;
	}

}