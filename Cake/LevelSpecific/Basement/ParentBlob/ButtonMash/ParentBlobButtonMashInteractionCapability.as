import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonMash.ParentBlobButtonMashComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;

class UParentBlobButtonMashInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY()
	UBlendSpace MashBlendSpace;

	AParentBlob ParentBlob;
	UParentBlobButtonMashComponent ButtonMashComp;

	bool bPlayingBlendSpace = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		ButtonMashComp = UParentBlobButtonMashComponent::GetOrCreate(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!ButtonMashComp.bButtonMashActive)
			return EHazeNetworkActivation::DontActivate;

		if (!ButtonMashComp.bCurrentButtonMashIsInteraction)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!ButtonMashComp.bButtonMashActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayingBlendSpace = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bPlayingBlendSpace)
		{
			ParentBlob.StopBlendSpace();
			ParentBlob.UnblockCapabilities(CapabilityTags::Movement, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float HorizontalBlendSpaceValue = 0.f;
		float VerticalBlendSpaceValue = 0.f;

		bool bAtLeastOnePlayerMashing = false;
		bool bMayTryingToMove = false;
		bool bCodyTryingToMove = false;

		if (ButtonMashComp.CurrentMayMashHandle.MashRateControlSide >= 2.5f)
		{
			bAtLeastOnePlayerMashing = true;
			HorizontalBlendSpaceValue -= 1.f;
			VerticalBlendSpaceValue = 1.f;
		}
		else
		{
			FVector MovementDir = ParentBlob.PlayerMovementDirection[Game::GetMay()];
			float MoveDot = ParentBlob.ActorForwardVector.DotProduct(MovementDir);
			if (MoveDot < 0.f)
				bMayTryingToMove = true;
		}

		if (ButtonMashComp.CurrentCodyMashHandle.MashRateControlSide >= 2.5f)
		{
			bAtLeastOnePlayerMashing = true;
			HorizontalBlendSpaceValue += 1.f;
			VerticalBlendSpaceValue = 1.f;
		}
		else
		{
			FVector MovementDir = ParentBlob.PlayerMovementDirection[Game::GetCody()];
			float MoveDot = ParentBlob.ActorForwardVector.DotProduct(MovementDir);
			if (MoveDot < 0.f)
				bCodyTryingToMove = true;
		}

		if (bMayTryingToMove || bCodyTryingToMove)
			VerticalBlendSpaceValue = 0.f;

		if (bAtLeastOnePlayerMashing)
			PlayBlendSpace();
		else
			StopBlendSpace();

		if (bPlayingBlendSpace)
			ParentBlob.SetBlendSpaceValues(HorizontalBlendSpaceValue, VerticalBlendSpaceValue);
	}

	void PlayBlendSpace()
	{
		if (bPlayingBlendSpace)
			return;

		ParentBlob.PlayBlendSpace(MashBlendSpace);
		bPlayingBlendSpace = true;
		ParentBlob.BlockCapabilities(CapabilityTags::Movement, this);
		ParentBlob.SmoothSetLocationAndRotation(ButtonMashComp.TargetStandTransform.Location, ButtonMashComp.TargetStandTransform.Rotator());
	}

	void StopBlendSpace()
	{
		if (!bPlayingBlendSpace)
			return;

		ParentBlob.StopBlendSpace();
		bPlayingBlendSpace = false;
		ParentBlob.UnblockCapabilities(CapabilityTags::Movement, this);
	}
}