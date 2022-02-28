import Vino.Movement.Components.CollisionIgnoreManagerComponent;

/* Temporarily ignore collision from a specific component when calculating movement. */
UFUNCTION(Category = "Movement")
void TemporarilyIgnoreComponentCollision(AHazeActor MovingActor, UPrimitiveComponent ComponentToIgnore, float IgnoreDuration)
{
	UCollisionIgnoreManagerComponent::GetOrCreate(MovingActor).TemporarilyIgnoreComponentCollision(ComponentToIgnore, IgnoreDuration);
}

/* Temporarily ignore collision from a specific actor when calculating movement. */
UFUNCTION(Category = "Movement")
void TemporarilyIgnoreActorCollision(AHazeActor MovingActor, AActor ActorToIgnore, float IgnoreDuration)
{
	UCollisionIgnoreManagerComponent::GetOrCreate(MovingActor).TemporarilyIgnoreActorCollision(ActorToIgnore, IgnoreDuration);
}