import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
struct FCastleChessSpawnGroups
{
	UPROPERTY()
	TArray<FCastleChessSpawnGroup> Groups;
}

struct FCastleChessSpawnGroup
{
	UPROPERTY()
	TArray<FVector2D> Coordinates;

	UPROPERTY()
	FRotator Rotation;
}

struct FCastleChessPieceSpawnData
{
	UPROPERTY()
	TSubclassOf<ACastleEnemy> Type;

	UPROPERTY()
	FVector2D Coordinate;

	UPROPERTY()
	FRotator Rotation = FRotator::ZeroRotator;
}

struct FCastleChessPieceType
{
	UPROPERTY()
	TSubclassOf<ACastleEnemy> Type;
	
	UPROPERTY()
	ECastleChessSpawnType SpawnType;
	
	bool opEquals(TSubclassOf<ACastleEnemy> OtherType)	
	{
		return Type.Get() == OtherType.Get();
	}

	bool opEquals(ECastleChessSpawnType OtherSpawnType)	
	{
		return SpawnType == OtherSpawnType;
	}
}

enum ECastleChessSpawnType
{
	Pawn,
	Bishop,
	Rook,
	Knight
}