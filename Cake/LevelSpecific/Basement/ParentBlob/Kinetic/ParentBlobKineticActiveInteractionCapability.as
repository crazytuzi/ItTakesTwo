import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticWidget;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticComponent;

class UParentBlobKineticActiveInteractionCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ParentBlobButtonHold");
	default CapabilityTags.Add(n"KineticTargeting");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;
	default TickGroupOrder = 101;

	AParentBlob ParentBlob;
	UParentBlobKineticComponent InteractionComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		InteractionComponent = UParentBlobKineticComponent::Get(ParentBlob);
	}
	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{ 
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(int i = 0; i < 2; ++i)
		{
			const FParentBlobKineticPlayerInputData& PlayerData = InteractionComponent.PlayerInputData[i];
			auto ActiveInteraction = PlayerData.TargetedInteraction;
			if(ActiveInteraction == nullptr)
				continue;

			if(ActiveInteraction.bHasBeenCompleted)
				continue;
			
			ActiveInteraction.UpdateProgress(DeltaTime, 
			InteractionComponent.PlayerIsHolding(EHazePlayer::May, ActiveInteraction)
			&& InteractionComponent.PlayerHasValidInput(EHazePlayer::May, ActiveInteraction), 
			InteractionComponent.PlayerIsHolding(EHazePlayer::Cody, ActiveInteraction)
			&& InteractionComponent.PlayerHasValidInput(EHazePlayer::Cody, ActiveInteraction));
			InteractionComponent.HoldWidget.OnStatusUpdate(ActiveInteraction.MayHoldProgress.Value, ActiveInteraction.CodyHoldProgress.Value);
		}
	}	
}