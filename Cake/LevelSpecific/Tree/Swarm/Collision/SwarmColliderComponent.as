

/**
	 Will initially only be used for Match & Sap queries. In some
	 encounters we'll extend the collider to include other collisions as well. 
	 that will be done on the blueprint layer. 

	 We use a box collision rather then the mesh itself because various UE4 
	 functions aren't really optimized for the number of bones the swarm has.
	 It is easier to have a dedicated collision component rather then overriding 
	 every virtual function we can find.
 */

class USwarmColliderComponent : UBoxComponent
{
	default bVisible = false;
	default bVisibleInReflectionCaptures = false;
	default bRenderInMainPass = false;
	default bReceivesDecals = false;
	default CollisionEnabled = ECollisionEnabled::QueryOnly;
	default bGenerateOverlapEvents = false;
	default SetGenerateOverlapEvents(false);
	default SetCollisionProfileName(n"NoCollision");
  	default BodyInstance.bNotifyRigidBodyCollision = false;
  	default BodyInstance.bUseCCD = false;
	default BodyInstance.bAutoWeld = false;
	default BodyInstance.SetbAutoWeld(false);
	default BodyInstance.bGenerateWakeEvents = false;
	default bOwnerNoSee = false;
	default bCanEverAffectNavigation = false;
	default bAffectDynamicIndirectLighting = false;
	default bCastDynamicShadow = false;
	default bUseAttachParentBound = true;
	default SetCollisionObjectType(ECollisionChannel::ECC_WorldDynamic);
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SetCollisionResponseToChannel(ECollisionChannel::WeaponTrace, ECollisionResponse::ECR_Overlap);
	default SetCollisionResponseToChannel(ECollisionChannel::SapTrace, ECollisionResponse::ECR_Overlap);
}