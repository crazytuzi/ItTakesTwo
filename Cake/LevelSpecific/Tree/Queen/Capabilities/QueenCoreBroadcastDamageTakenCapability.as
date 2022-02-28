
import Cake.LevelSpecific.Tree.Queen.Capabilities.QueenBaseCapability;

UCLASS()
class UQueenCoreBroadcastDamageTakenCapabilty : UQueenBaseCapability
{
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Queen.SapResponseComp.OnSapExploded.AddUFunction(this, n"OnSapExploded");
		Queen.SapResponseComp.OnSapExplodedProximity.AddUFunction(this, n"OnSapExplodedProximity");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Queen.SapResponseComp.OnSapExploded.Unbind(this, n"OnSapExploded");
		Queen.SapResponseComp.OnSapExplodedProximity.Unbind(this, n"OnSapExplodedProximity");
	}

	UFUNCTION()
	void OnSapExploded(
		FSapAttachTarget Where,
		float Mass
	)
	{
		HandleSapExplosion(Where, Mass);
	}

	UFUNCTION()
	void OnSapExplodedProximity(
		FSapAttachTarget Where,
		float Mass,
		float Distance
	)
	{
		HandleSapExplosion(Where, Mass);
	}

	void HandleSapExplosion(
		FSapAttachTarget Where,
		float Mass
	)
	{
		Queen.OnDamageTaken.Broadcast(
			Where.WorldLocation, 
			Where.Component, 
			Where.Socket, 
			Mass
		);
	}

}