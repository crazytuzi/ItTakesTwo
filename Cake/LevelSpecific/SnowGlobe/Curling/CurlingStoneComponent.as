event void FReleaseStone();

class UCurlingStoneComponent : UActorComponent
{
	FVector PullDirection;
	float Power;

	FReleaseStone EventReleaseStone;
}