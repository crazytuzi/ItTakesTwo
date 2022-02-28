import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

struct FCastleChessWave
{
	UPROPERTY()
	TArray<FCastleChessSpawn> Spawns;
}

USTRUCT()
struct FCastleChessSpawn
{
	UPROPERTY()
	TSubclassOf<ACastleEnemy> Type;

	UPROPERTY()
	FVector2D Coordinate;

	UPROPERTY()
	FRotator Rotation;

	FCastleChessSpawn(TSubclassOf<ACastleEnemy> InType, FVector2D InCoordinate, FRotator InRotation = FRotator::ZeroRotator)
	{
		Type = InType;
		Coordinate = InCoordinate;
		Rotation = InRotation;
	}
}