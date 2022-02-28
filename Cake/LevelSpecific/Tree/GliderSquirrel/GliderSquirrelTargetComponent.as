class UGliderSquirrelTargetComponent : UHazeSkeletalMeshComponentBase
{
	int NumAttackingSquirrels = 0;

	bool HasAttackingSquirrels()
	{
		return NumAttackingSquirrels > 0;
	}
}