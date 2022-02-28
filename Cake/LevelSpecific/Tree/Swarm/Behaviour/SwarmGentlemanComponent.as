import Vino.AI.Components.GentlemanFightingComponent;
 
/* GentlemanFightingComponent + Swarm specific stuff */ 

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmGentlemanComponent : UGentlemanFightingComponent
{
	UFUNCTION(NetFunction)
    bool NetClaimAction(const FName& Tag, AHazeActor Claimant, int InMaxClaimants = 1)
    {
		// we might get a delayed network message just as the swarm dies
		if(Claimant.IsActorDisabled())
			return false;

		const bool bClaimed = ClaimAction(Tag, Claimant);

		// Assuming that we always check if it is claimable before calling the netfunction
		ensure(bClaimed);

		if (bClaimed)
		{
			int DesiredMaxNumClaimaints = InMaxClaimants;
			const int CurrentMaxClaimants = GetMaxAllowedClaimants(Tag);
			if(CurrentMaxClaimants != 1)
				DesiredMaxNumClaimaints = FMath::Min(InMaxClaimants, CurrentMaxClaimants);

			TArray<UObject> CurrentClaimaints;
			GetClaimants(Tag, CurrentClaimaints);
			DesiredMaxNumClaimaints = FMath::Max(DesiredMaxNumClaimaints, CurrentClaimaints.Num());

			SetMaxAllowedClaimants(Tag, DesiredMaxNumClaimaints);
		}

		return bClaimed;
	}

	UFUNCTION(NetFunction)
    void NetUnclaimAction(const FName& Tag, UObject InClaimant)
    {
		ReleaseAction(Tag, InClaimant);
	}

}