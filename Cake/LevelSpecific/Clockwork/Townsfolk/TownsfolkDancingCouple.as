import Cake.LevelSpecific.Clockwork.Townsfolk.StaticTownsFolkActor;

class ATownsfolkDancingCouple : AStaticTownsFolkActor
{
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AddActorWorldRotation(FRotator(0.f, 50.f * DeltaTime, 0.f));
	}
}