import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ButtonHold.ParentBlobButtonHoldComponent;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticComponent;

class UParentBlobKineticAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AParentBlob ParentBlob;
	UParentBlobKineticComponent HoldComp;

	bool bPlayingBlendSpace = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		HoldComp = UParentBlobKineticComponent::Get(ParentBlob);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// if (HoldComp.ActiveInteraction == nullptr)
		// 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if (HoldComp.ActiveInteraction == nullptr)
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

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
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float HorizontalBlendSpaceValue = 0.f;
		float VerticalBlendSpaceValue = 0.f;

		bool bAtLeastOnePlayerHolding = false;
		bool bMayTryingToMove = false;
		bool bCodyTryingToMove = false;

		if (HoldComp.PlayerIsHolding(EHazePlayer::May))
		{
			bAtLeastOnePlayerHolding = true;
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

		if (HoldComp.PlayerIsHolding(EHazePlayer::Cody))
		{
			bAtLeastOnePlayerHolding = true;
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

		if (ParentBlob.MoveComp.GetVelocity() != FVector::ZeroVector)
			StopBlendSpace();
		else if (bAtLeastOnePlayerHolding)
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

		ParentBlob.PlayBlendSpace(HoldComp.HoldBS);
		bPlayingBlendSpace = true;
	}

	void StopBlendSpace()
	{
		if (!bPlayingBlendSpace)
			return;

		ParentBlob.StopBlendSpace();
		bPlayingBlendSpace = false;
	}
}