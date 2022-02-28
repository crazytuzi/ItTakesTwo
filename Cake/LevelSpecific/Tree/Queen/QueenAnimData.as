class UQueenAnimData : UActorComponent 
{
	UPROPERTY()
	bool bAscending;

	UPROPERTY()
	bool bAttacking = false;

	UPROPERTY()
	int Phase = 0;
}