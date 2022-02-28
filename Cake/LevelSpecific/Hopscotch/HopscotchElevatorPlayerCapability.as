import Cake.LevelSpecific.Hopscotch.AnimNotify_FidgetSpinnerAttachElevator;
import Cake.LevelSpecific.Hopscotch.HopscotchElevator;
import Cake.LevelSpecific.Hopscotch.HopscotchElevatorComponent;

class UHopscotchElevatorPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HopscotchElevatorPlayerCapability");

	default CapabilityDebugCategory = n"HopscotchElevatorPlayerCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	/* ------- Animation ------- */

	// UPROPERTY()
	// UAnimSequence CodyEnter;

	UPROPERTY()
	UAnimSequence CodyAttach;

	UPROPERTY()
	UAnimSequence CodyMH;

	UPROPERTY()
	UAnimSequence CodySpin;

	// UPROPERTY()
	// UAnimSequence MayEnter;

	UPROPERTY()
	UAnimSequence MayAttach;

	UPROPERTY()
	UAnimSequence MayMH;

	UPROPERTY()
	UAnimSequence MaySpin;

	//UAnimSequence CurrentEnter;
	UAnimSequence CurrentAttach;
	UAnimSequence CurrentMH;
	UAnimSequence CurrentSpin;

	float CurrentMashRate = 0.f;
	bool bPlayingSpinAnim = false;

	/* ----------------------  */

	AHazePlayerCharacter Player;
	AHopscotchElevator Elevator;
	USceneComponent AttachComp;
	UHopscotchElevatorComponent ElevatorComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ElevatorComp = UHopscotchElevatorComponent::GetOrCreate(Player);

		CurrentAttach = Player == Game::GetCody() ? CodyAttach : MayAttach;
		CurrentMH = Player == Game::GetCody() ? CodyMH : MayMH;
		CurrentSpin = Player == Game::GetCody() ? CodySpin : MaySpin;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(ElevatorComp.AttachComp == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElevatorComp.AttachComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"FidgetSpinner", this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this, n"HopscotchElevator");
		Player.AttachToComponent(ElevatorComp.AttachComp, n"", EAttachmentRule::SnapToTarget);

		if (Player == Game::GetCody())
		{
			Player.BindOneShotAnimNotifyDelegate(
			UAnimNotify_FidgetSpinnerAttachElevator::StaticClass(),
			FHazeAnimNotifyDelegate(this, n"OnCodyAttach"));
		}

		FHazeAnimationDelegate AttachBlendOut;
		AttachBlendOut.BindUFunction(this, n"OnAttachBlendOut");
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), AttachBlendOut, CurrentAttach);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"FidgetSpinner", this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.StopAllSlotAnimations();
	}

	UFUNCTION()
	void OnAttachBlendOut()
	{
		if (Player == Game::GetMay())
		{
			ElevatorComp.Elevator.AttachLeftFidgetSpinner();
			ElevatorComp.Elevator.StartLeftButtonMash();
		} else
		{
			ElevatorComp.Elevator.StartRightButtonMash();
		}

		Player.PlaySlotAnimation(Animation = CurrentMH, bLoop = true);
	}

	UFUNCTION()
	void OnCodyAttach(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		ElevatorComp.Elevator.AttachRightFidgetSpinner();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!Player.HasControl())
			return;

		if (Player == Game::GetMay())
			CurrentMashRate = GetAttributeValue(n"LeftElevatorMashRate");
		else
			CurrentMashRate = GetAttributeValue(n"RightElevatorMashRate");

		if (CurrentMashRate > 3.f && !bPlayingSpinAnim)
			NetPlaySpinAnim();

		if (CurrentMashRate < 3.f && bPlayingSpinAnim)
			NetPlayMhAnim();
	}

	UFUNCTION(NetFunction)
	void NetPlaySpinAnim()
	{
		bPlayingSpinAnim = true;
		FHazeAnimationDelegate SpinBlendingOut;
		SpinBlendingOut.BindUFunction(this, n"OnSpinBlendingOut");
		Player.PlaySlotAnimation(OnBlendingOut = SpinBlendingOut, Animation = CurrentSpin, bLoop = true);
	}

	UFUNCTION(NetFunction)
	void NetPlayMhAnim()
	{	
		bPlayingSpinAnim = false;
		Player.PlaySlotAnimation(Animation = CurrentMH, bLoop = true);
	}

	UFUNCTION()
	void OnSpinBlendingOut()
	{
		// if (CurrentMashRate < 3.f)
		// 	Player.PlaySlotAnimation(Animation = CurrentMH, bLoop = true);
	}
}