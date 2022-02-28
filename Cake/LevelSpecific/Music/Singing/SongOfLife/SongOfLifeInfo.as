
struct FSongOfLifeInfo
{
	// The actor that instigated the song of life.
	UPROPERTY()
	AHazePlayerCharacter Instigator;
}

event void FSongOfLifeDelegate(FSongOfLifeInfo Info);
