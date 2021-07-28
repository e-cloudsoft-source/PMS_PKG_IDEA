public without sharing class CommCsvUtils {


    /**
     * The default separator to use if none is supplied to the constructor.
     */
    public static final String DEFAULT_SEPARATOR = ',';

    public static final Integer INITIAL_READ_SIZE = 128;

    /**
     * The default quote character to use if none is supplied to the
     * constructor.
     */
    public static final String DEFAULT_QUOTE_CHARACTER = '"';


    /**
     * The default escape character to use if none is supplied to the
     * constructor.
     */
    public static final String DEFAULT_ESCAPE_CHARACTER = '\\';

    /**
     * The default strict quote behavior to use if none is supplied to the
     * constructor
     */
    public static final boolean DEFAULT_STRICT_QUOTES = false;

    /**
     * The default leading whitespace behavior to use if none is supplied to the
     * constructor
     */
    public static final boolean DEFAULT_IGNORE_LEADING_WHITESPACE = true;

    /**
     * This is the "null" character - if a value is set to this then it is ignored.
     * I.E. if the quote character is set to null then there is no quote character.
     */
    public static final String NULL_CHARACTER = '\\0';

	public class CSVParser {

	    private final String separator;

	    private final String quotechar;

	    private final String escape;

	    private final boolean strictQuotes;

	    private String pending;
	    private boolean inField = false;

	    private final boolean ignoreLeadingWhiteSpace;

	    /**
	     * Constructs CSVParser using a comma for the separator.
	     */
	    public CSVParser() {
	        this(DEFAULT_SEPARATOR, DEFAULT_QUOTE_CHARACTER, DEFAULT_ESCAPE_CHARACTER);
	    }

	    /**
	     * Constructs CSVParser with supplied separator.
	     *
	     * @param separator the delimiter to use for separating entries.
	     */
	    public CSVParser(String separator) {
	        this(separator, DEFAULT_QUOTE_CHARACTER, DEFAULT_ESCAPE_CHARACTER);
	    }


	    /**
	     * Constructs CSVParser with supplied separator and quote char.
	     *
	     * @param separator the delimiter to use for separating entries
	     * @param quotechar the character to use for quoted elements
	     */
	    public CSVParser(String separator, String quotechar) {
	        this(separator, quotechar, DEFAULT_ESCAPE_CHARACTER);
	    }

	    /**
	     * Constructs CSVReader with supplied separator and quote char.
	     *
	     * @param separator the delimiter to use for separating entries
	     * @param quotechar the character to use for quoted elements
	     * @param escape    the character to use for escaping a separator or quote
	     */
	    public CSVParser(String separator, String quotechar, String escape) {
	        this(separator, quotechar, escape, DEFAULT_STRICT_QUOTES);
	    }

	    /**
	     * Constructs CSVReader with supplied separator and quote char.
	     * Allows setting the "strict quotes" flag
	     *
	     * @param separator    the delimiter to use for separating entries
	     * @param quotechar    the character to use for quoted elements
	     * @param escape       the character to use for escaping a separator or quote
	     * @param strictQuotes if true, characters outside the quotes are ignored
	     */
	    public CSVParser(String separator, String quotechar, String escape, boolean strictQuotes) {
	        this(separator, quotechar, escape, strictQuotes, DEFAULT_IGNORE_LEADING_WHITESPACE);
	    }

	    /**
	     * Constructs CSVReader with supplied separator and quote char.
	     * Allows setting the "strict quotes" and "ignore leading whitespace" flags
	     *
	     * @param separator               the delimiter to use for separating entries
	     * @param quotechar               the character to use for quoted elements
	     * @param escape                  the character to use for escaping a separator or quote
	     * @param strictQuotes            if true, characters outside the quotes are ignored
	     * @param ignoreLeadingWhiteSpace if true, white space in front of a quote in a field is ignored
	     */
	    public CSVParser(String separator, String quotechar, String escape, boolean strictQuotes, boolean ignoreLeadingWhiteSpace) {
	        if (anyCharactersAreTheSame(separator, quotechar, escape)) {
	            throw new CommException('The separator, quote, and escape characters must be different!');
	        }
	        if (separator == NULL_CHARACTER) {
	            throw new CommException('The separator character must be defined!');
	        }
	        this.separator = separator;
	        this.quotechar = quotechar;
	        this.escape = escape;
	        this.strictQuotes = strictQuotes;
	        this.ignoreLeadingWhiteSpace = ignoreLeadingWhiteSpace;
	    }

	    private boolean anyCharactersAreTheSame(String separator, String quotechar, String escape) {
	        return isSameCharacter(separator, quotechar) || isSameCharacter(separator, escape) || isSameCharacter(quotechar, escape);
	    }

	    private boolean isSameCharacter(String c1, String c2) {
	        return c1 != NULL_CHARACTER && c1 == c2;
	    }

	    /**
	     * @return true if something was left over from last call(s)
	     */
	    public boolean isPending() {
	        return pending != null;
	    }

	    public String[] parseLineMulti(String nextLine) {
	        return parseLine(nextLine, true);
	    }

	    public String[] parseLine(String nextLine) {
	        return parseLine(nextLine, false);
	    }

	    /**
	     * Parses an incoming String and returns an array of elements.
	     *
	     * @param nextLine the string to parse
	     * @param multi
	     * @return the comma-tokenized list of elements, or null if nextLine is null
	     * @throws IOException if bad things happen during the read
	     */
	    private String[] parseLine(String nextLine, boolean multi) {

	        if (!multi && pending != null) {
	            pending = null;
	        }

	        if (nextLine == null) {
	            if (pending != null) {
	                String s = pending;
	                pending = null;
	                return new String[]{s};
	            } else {
	                return null;
	            }
	        }

	        List<String> tokensOnThisLine = new List<String>();
	        //StringBuilder sb = new StringBuilder(INITIAL_READ_SIZE);
	        String sb = '';
	        boolean inQuotes = false;
	        if (pending != null) {
	            sb += (pending);
	            pending = null;
	            inQuotes = true;
	        }
	        for (Integer i = 0; i < nextLine.length(); i++) {

	            String c = nextLine.substring(i, i+1);
	            if (c == this.escape) {
	                if (isNextCharacterEscapable(nextLine, inQuotes || inField, i)) {
	                    sb += (nextLine.substring(i + 1, i+2));
	                    i++;
	                }
	            } else if (c == quotechar) {
	                if (isNextCharacterEscapedQuote(nextLine, inQuotes || inField, i)) {
	                    sb += (nextLine.substring(i + 1, i+2));
	                    i++;
	                } else {
	                    //inQuotes = !inQuotes;

	                    // the tricky case of an embedded quote in the middle: a,bc"d"ef,g
	                    if (!strictQuotes) {
	                        if (i > 2 //not on the beginning of the line
	                                && nextLine.substring(i - 1, i) != this.separator //not at the beginning of an escape sequence
	                                && nextLine.length() > (i + 1) &&
	                                nextLine.substring(i + 1, i+2) != this.separator //not at the   end of an escape sequence
	                                ) {

	                            if (ignoreLeadingWhiteSpace && sb.length() > 0 && isAllWhiteSpace(sb)) {
	                                //sb.setLength(0);  //discard white space leading up to quote
	                                sb = '';
	                            } else {
	                                sb += (c);
	                                //continue;
	                            }

	                        }
	                    }

	                    inQuotes = !inQuotes;
	                }
	                inField = !inField;
	            } else if (c == separator && !inQuotes) {
	                tokensOnThisLine.add(sb);
	                //sb.setLength(0); // start work on next token
	                sb = '';
	                inField = false;
	            } else {
	                if (!strictQuotes || inQuotes) {
	                    sb += (c);
	                    inField = true;
	                }
	            }
	        }
	        // line is done - check status
	        if (inQuotes) {
	            if (multi) {
	                // continuing a quoted section, re-append newline
	                sb += ('\n');
	                pending = sb;
	                sb = null; // this partial content is not to be added to field list yet
	            } else {
	                throw new CommException('Un-terminated quoted field at end of CSV line');
	            }
	        }
	        if (sb != null) {
	            tokensOnThisLine.add(sb);
	        }
	        //return tokensOnThisLine.toArray(new String[tokensOnThisLine.size()]);
            String[] retStrArr = new String[tokensOnThisLine.size()];
            for (Integer index = 0; index < tokensOnThisLine.size(); index++) {
                retStrArr[index] = tokensOnThisLine[index];
            }
            return retStrArr;
	    }

	    /**
	     * precondition: the current character is a quote or an escape
	     *
	     * @param nextLine the current line
	     * @param inQuotes true if the current context is quoted
	     * @param i        current index in line
	     * @return true if the following character is a quote
	     */
	    private boolean isNextCharacterEscapedQuote(String nextLine, boolean inQuotes, Integer i) {
	        return inQuotes  // we are in quotes, therefore there can be escaped quotes in here.
	                && nextLine.length() > (i + 1)  // there is indeed another character to check.
	                && nextLine.substring(i + 1, i+2) == quotechar;
	    }

	    /**
	     * precondition: the current character is an escape
	     *
	     * @param nextLine the current line
	     * @param inQuotes true if the current context is quoted
	     * @param i        current index in line
	     * @return true if the following character is a quote
	     */
	    boolean isNextCharacterEscapable(String nextLine, boolean inQuotes, Integer i) {
	        return inQuotes  // we are in quotes, therefore there can be escaped quotes in here.
	                && nextLine.length() > (i + 1)  // there is indeed another character to check.
	                && (nextLine.substring(i + 1, i+2) == quotechar || nextLine.substring(i + 1, i+2) == this.escape);
	    }

	    /**
	     * precondition: sb.length() > 0
	     *
	     * @param sb A sequence of characters to examine
	     * @return true if every character in the sequence is whitespace
	     */
	    boolean isAllWhiteSpace(String sb) {
	    	return (sb != null || sb.trim().length() >0 );
	    }
	}

    /**
    * Csv Reader Class
    **/
    private static Pattern quotePattern = Pattern.compile('(?<!")"(?!")');
	public class CsvReader {
	  //  Csv Reader -- courtesy of http://blog.nicocrm.com/2011/03/06/parse-csv-file-in-salesforce-apex/
	  //
	  //  Usage: Call Constructor with entire Csv Stream then call readLine to get array of string tokens for each line; first row will be header row. readLine returns null at end of stream

	  private String     delim = ',';

	  private String[]   buffer;              // the input data for entire CSV file
      public Integer getTotalLines() {return buffer.size();}
      public String[] getAllReadCsv(){
        return buffer;
      }
      public void setUnReadCsv(String[] buf) {
      	buffer = buf;
      }
      public Boolean isHaveUnReacCsv() {
      	if (this.buffer.isEmpty()) return false;
      	return true;
      }
	  //  ------------------------------
	  //  Constructors
	  //  ------------------------------
	  public CsvReader(String data){
	    this.buffer = (data == null ? new List<String>() : data.split('\n'));
	  }

	  public CsvReader(String data, String delim){
	    this.buffer = (data == null ? new List<String>() : data.split('\n'));
	    this.delim = delim;
	  }

      public CsvReader(String[] data){
        this.buffer = (data == null ? new List<String>() : data);
      }
	  //  -------------------------------
	  //  readLine - returns array of csv tokens as strings; reads through buffer, removing from buffer as each line is located in toto. Return null if end of stream.
	  //  -------------------------------
	  public String[] readLine(){
	    if(this.buffer.size() == 0) return null;
	    String     line     = this.buffer.remove(0);    // grab first part of stream up to newline; remove from buffer
	    String[]   parts     = new String[] {};        // result list of tokens for one line
	    while(line != ''){
	      Integer next = 0;
	      if(line.startsWith('"')){
	        line = line.substring(1); // strip initial "
	        Integer quoteIndex = findQuote(line, 0);    // Look for closing " on same line
	        while(quoteIndex == -1){            //  not found, we must have a newline within a quoted token
	          if(buffer.size() == 0){
	            // EOT!
	            quoteIndex = line.length();
	          }
	          else {
	            // grab the next line and look to see if closing " can be found
	            Integer skip = line.length();
	            line += '\n' + this.buffer.remove(0);
	            quoteIndex = findQuote(line, skip);
	          }
	        }
	        // we have a quoted token, advance to comma
	        next = quoteIndex + 1;
	        parts.add(line.substring(0, quoteIndex).replace('""', '"'));
	        }
	      else {    // non-quoted token, token end is at delim
	        next = line.indexOf(this.delim, next);
	        if(next == -1)
	          next = line.length();
	        // NB in Substring, "endindex" is the index of the character AFTER the last index to get
	        parts.add(line.substring(0, next));
	      }
	      if(next == line.length() - 1)
	      // case of a terminating comma.
	        parts.add('');
	      line = next < line.length() ? line.substring(next+1) : '';
	    }
	    if(parts.size() == 0)
	      // empty string - we still want to return something...
	      parts.add('');
	    return parts;
	  }



	  //  -------------------------------------------------
	  //  Helper: findQuote - find next quote " in line
	  private Integer findQuote(String line, Integer skip){
	    Matcher m = quotePattern.matcher(line);
	    m.region(skip, m.regionEnd());
	    if(!m.find())
	      return -1;
	    return m.start();
	  }


	}

}