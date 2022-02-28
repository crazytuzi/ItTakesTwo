import Vino.AI.Components.GentlemanFightingComponent; 

class ADisableAttackVolume : ATriggerVolume
{

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if(OtherActor == nullptr)
			return; 
		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(OtherActor);
		if(GentlemanComp == nullptr)
			return;
		GentlemanComp.SetMaxAllowedClaimants(n"IsAttackedAllowed", 0); 

	}
	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if(OtherActor == nullptr)
			return; 
		UGentlemanFightingComponent GentlemanComp = UGentlemanFightingComponent::Get(OtherActor);
		if(GentlemanComp == nullptr)
			return;
		GentlemanComp.SetMaxAllowedClaimants(n"IsAttackedAllowed", 1); 
	
	}
}