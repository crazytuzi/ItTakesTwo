import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourComponent;
import Cake.Weapons.Sap.SapResponseComponent;

class UBeetleVOPlayerBarksCapability : UHazeCapability
{
	UBeetleBehaviourComponent BehaviourComp;
	USapResponseComponent SapResponseComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UBeetleBehaviourComponent::Get(Owner);
		SapResponseComp = USapResponseComponent::Get(Owner);
		
		SapResponseComp.OnHitNonStick.AddUFunction(this, n"OnSapBounce");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSapBounce(FSapAttachTarget Where, float Mass)
	{
		if (IsBlocked())
			return;
		if (BehaviourComp.State == EBeetleState::None)
			return;
		if (IsPlayerDead(Game::Cody) || IsPlayerDead(Game::May))
			return;
		PlayFoghornVOBankEvent(BehaviourComp.VOBankDataAsset, n"FoghornDBTreeWaspNestBeetleFight");	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Never need to be active, delegates only
		return EHazeNetworkActivation::DontActivate;
	}	
}
