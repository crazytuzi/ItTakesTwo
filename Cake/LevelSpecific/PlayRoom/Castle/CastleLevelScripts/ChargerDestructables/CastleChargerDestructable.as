import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleChargableComponent;
class ACastleChargerDestructible : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent DestructibleMesh;

	UPROPERTY(DefaultComponent)
	UCastleChargableComponent ChargableComp;
}