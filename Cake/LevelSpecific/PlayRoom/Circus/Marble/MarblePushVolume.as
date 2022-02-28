import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;

class AMarblePushVolume : AVolume
{
	UPROPERTY(DefaultComponent)
	UArrowComponent Direction;

	UPROPERTY()
	float Force = 10000;

	AMarbleBall Marble;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AMarbleBall InMarble = Cast<AMarbleBall>(OtherActor);
		if (InMarble != nullptr)
		{
			Marble = InMarble;
			SetActorTickEnabled(true);
		}
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AMarbleBall InMarble = Cast<AMarbleBall>(OtherActor);
		if (InMarble != nullptr)
		{
			SetActorTickEnabled(false);
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float Deltatime)
	{
		if(Marble.Mesh.IsSimulatingPhysics())
		{
			Marble.Mesh.AddForce(Direction.ForwardVector * Force);
		}
		
	}
}